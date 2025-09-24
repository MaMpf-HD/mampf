# Integrity & Invariants

Aggregated rules ensuring durable correctness. When feasible, enforce with DB constraints + background reconcile tasks.

## 1. Registration & Allocation
Logical
- ≤ 1 confirmed Registration::UserRegistration per (user, registration_campaign).
- Registration::UserRegistration.status ∈ {pending, confirmed, rejected}.
- preference_based campaigns: every pending registration has preference_rank (1..N) unique per (user, campaign).
- Capacity never exceeded at allocation (solver respects caps; FCFS checks).
- Campaign finalized exactly once (finalize! idempotent).
Stored
- registration_items.assigned_count == confirmed count (reconcile job allowed).
Indexes (suggested)
- UNIQUE (registration_campaign_id, user_id) WHERE status = 'confirmed'
- UNIQUE (user_id, registration_campaign_id, preference_rank) WHERE preference_rank IS NOT NULL

## 2. Rosters & Materialization
- materialize_allocation! overwrites roster to match confirmed set (initial snapshot).
- Post-allocation roster changes do not mutate historical Registration::UserRegistration decisions.
- Roster operations atomic (RegisterableRosterService transactions).
- Capacity enforcement except when explicit override.

## 3. Assessments & Grading
- One AssessmentParticipation per (assessment, user) (unique index).
- One TaskPoint per (assessment_participation, task) (unique index).
- points_total = Σ published (or all) TaskPoints.points (deterministic recompute).
- Task exists only if assessment.requires_points.
- TaskPoint.points ≤ task.max_points (validation).
- Locked / published participations immutable (application guard).

## 4. Exam Eligibility
- One ExamEligibilityRecord per (lecture, user).
- final_status = override_status OR computed_status.
- Overrides immutable timestamp (override_at) once set.
- Recompute does NOT erase overrides.

## 5. Grading Schemes
- ≤ 1 active GradeScheme per assessment (or versioned with single active flag).
- Applying identical version_hash is a no-op.
- Manual grade override preserved across reapplication.

## 6. Algorithm / Solver
- Flow assigns each user to ≤ 1 real item.
- Total assigned to item ≤ item.registerable.capacity.
- If allow_unassigned: either real item edge or dummy edge chosen (exclusivity).
- Solver failures push campaign to safe error state (no partial writes).

## 7. Policy Engine
- Policies evaluated ascending position with stable ordering.
- First failure short‑circuits; no side effects after failure.
- Policy trace retained in memory per call (optional persisted audit future).

## 8. Data Consistency Reconciles (Recommended Jobs)
Job types:
- RecountAssignedCountsJob: recalc assigned_count from confirmed registrations.
- ParticipationTotalsJob: recompute points_total from TaskPoints.
- EligibilityDriftJob: recompute eligibility for users changed since last snapshot.
- OrphanTaskPointsJob: assert every TaskPoint has matching participation + task.

## 9. Suggested Database Constraints (Pseudo Rails Migrations)
```ruby
add_index :user_registrations,
		  [:registration_campaign_id, :user_id],
		  unique: true,
		  where: "status = 1" # assuming 1=confirmed enum

add_index :user_registrations,
		  [:user_id, :registration_campaign_id, :preference_rank],
		  unique: true,
		  where: "preference_rank IS NOT NULL"

add_index :assessment_participations,
		  [:assessment_id, :user_id],
		  unique: true

add_index :task_points,
		  [:assessment_participation_id, :task_id],
		  unique: true

add_index :exam_eligibility_records,
		  [:lecture_id, :user_id],
		  unique: true
```

## 10. Monitoring & Alerts
Metrics / checks:
- Orphan registrations (registration_item missing) = 0.
- Solver failures in last 24h = 0 (alert if >0).
- Drift: max(|assigned_count - confirmed_count|) per item < threshold.
- Eligibility stale age (now - last_computed_at) < SLA during registration window.

## 11. Idempotency Patterns
- finalize!: safe to call multiple times (no duplicate materialization).
- materialize_allocation!: set roster to exact set (not additive).
- Grade scheme apply: compares version_hash; re-run safe.
- Eligibility compute: upsert pattern.

## 12. Security / Authorization Notes
(Not exhaustive)
- Only staff create/modify campaigns & policies.
- Users can only create registrations for open campaigns and themselves.
- Roster service restricted to staff roles.

## 13. Quick Audit Checklist
- Random sample item: confirmed IDs == roster_user_ids (if still initial).
- Random sample assessment: points_total matches sum(task_points).
- Eligibility overrides present? Verify override_reason non-null.
- Registration::Policy ordering continuous (no gaps) & deterministic.

