# Integrity & Invariants

This chapter documents the key invariants and integrity constraints that ensure system correctness throughout the semester lifecycle.

```admonish tip "Enforcement Strategy"
When feasible, enforce constraints at the database level. For complex business rules, use application-level validations and background reconciliation jobs.
```

---

## 1. Registration & Allocation

### Database Constraints

```ruby
# One confirmed submission per user per campaign
add_index :registration_submissions,
          [:registration_campaign_id, :user_id],
          unique: true,
          where: "status = 'confirmed'",
          name: "idx_unique_confirmed_submission"

# Unique preference ranks per user per campaign
add_index :registration_submissions,
          [:user_id, :registration_campaign_id, :preference_rank],
          unique: true,
          where: "preference_rank IS NOT NULL",
          name: "idx_unique_preference_rank"
```

### Application-Level Invariants

| Invariant | Enforcement |
|-----------|-------------|
| `Registration::UserRegistration.status ∈ {pending, confirmed, rejected}` | Enum validation |
| At most one confirmed submission per (user, campaign) | Unique index |
| Preference-based campaigns: each pending submission has unique rank | Unique index + validation |
| Capacity never exceeded at allocation | Allocation algorithm respects `registerable.capacity` |
| Campaign finalized exactly once | `finalize!` idempotent with status check |
| `assigned_count` matches confirmed submissions | Background reconciliation job |

---

## 2. Rosters & Materialization

### Core Invariants

| Invariant | Details |
|-----------|---------|
| Initial roster snapshot | `materialize_allocation!` sets roster to match confirmed submissions |
| Historical integrity | Post-allocation roster changes don't mutate `Registration::UserRegistration` records |
| Atomic operations | `Roster::MaintenanceService` uses transactions |
| Capacity enforcement | Enforced unless explicit override by staff |
| Audit trail | All roster changes logged with actor, reason, timestamp |

### Reconciliation

Background job periodically checks:
- Roster user count vs. capacity limit
- Orphan roster entries (user deleted but still in roster)

---

## 3. Assessments & Grading

### Database Constraints

```ruby
# One participation per (assessment, user)
add_index :assessment_participations,
          [:assessment_id, :user_id],
          unique: true,
          name: "idx_unique_participation"

# One task point per (participation, task)
add_index :assessment_task_points,
          [:participation_id, :task_id],
          unique: true,
          name: "idx_unique_task_point"

# Foreign key integrity
add_foreign_key :assessment_tasks, :assessments
add_foreign_key :assessment_task_points, :assessment_tasks, column: :task_id
add_foreign_key :assessment_task_points, :assessment_participations, column: :participation_id
```

### Application-Level Invariants

| Invariant | Enforcement |
|-----------|-------------|
| `Participation.total_points = sum(task_points.points)` | Automatic recomputation on `TaskPoint` save |
| `TaskPoint.points ≤ Task.max_points` | Validation on save |
| Task records exist only if `Assessment` has tasks | Validation |
| Results visible only when `Assessment.results_published = true` | Controller authorization |
| `Participation.submitted_at` persists across status changes | Never overwritten after initial set |

### Multiple Choice Exam Constraints

```ruby
# At most one MC task per assessment
# Enforced via validation: at_most_one_mc_task_per_assessment

# MC flag only for exams
# Enforced via validation: mc_flag_only_for_exams

# Grade scheme only for MC tasks
# Enforced via validation: grade_scheme_only_for_mc_tasks
```

| Invariant | Details |
|-----------|---------|
| `is_multiple_choice = true` only for exams | Application validation checks `assessable.is_a?(Exam)` |
| At most one MC task per assessment | Scoped uniqueness validation |
| Task-level grade scheme only for MC tasks | Validation ensures `grade_scheme_id` only set if `is_multiple_choice = true` |
| MC threshold between 50% and 60% | Computed by `McGrader` with sliding clause |

---

## 4. Exam Eligibility

### Database Constraints

```ruby
# One eligibility record per (lecture, user)
add_index :exam_eligibility_records,
          [:lecture_id, :user_id],
          unique: true,
          name: "idx_unique_eligibility_record"
```

### Application-Level Invariants

| Invariant | Enforcement |
|-----------|-------------|
| One record per (lecture, user) | Unique index |
| `final_status = override_status ?? computed_status` | Computed property |
| Override immutable once set | `override_at` timestamp prevents changes |
| Recomputation preserves overrides | `ComputationService` only updates `computed_status` |
| Override requires reason | Validation ensures `override_reason` present if `override_status` set |

---

## 5. Grade Schemes

### Invariants

| Invariant | Details |
|-----------|---------|
| At most one active scheme per assessment | Assessment `belongs_to :grade_scheme` |
| Identical `version_hash` = no-op | Applier checks hash before reapplication |
| Manual overrides preserved | Overridden participations skipped during reapplication |
| Bands cover full range | Validation ensures 0.0 to 1.0 coverage |

---

## 6. Allocation Algorithm

### Preference-Based (Flow Network)

| Invariant | Details |
|-----------|---------|
| Each user assigned to ≤ 1 item | Flow solver ensures exclusivity |
| Total assigned to item ≤ capacity | Capacity constraint in network |
| Unassigned users get dummy edge | If `allow_unassigned = true` |
| No partial writes on failure | Transaction rollback on solver error |

### First-Come-First-Serve

| Invariant | Details |
|-----------|---------|
| Submissions processed in timestamp order | Ordered query by `created_at` |
| Capacity checked atomically | Database-level row locking |
| Concurrent submissions handled safely | Pessimistic locking or retry logic |

---

## 7. Policy Engine

### Invariants

| Invariant | Details |
|-----------|---------|
| Policies evaluated in ascending `position` order | Stable sort ensures deterministic evaluation |
| First failure short-circuits | Remaining policies not evaluated |
| No side effects on policy failure | Read-only policy checks |
| Policy trace retained per request | For debugging and audit purposes |

---

## 8. Data Consistency Reconciliation

### Recommended Background Jobs

| Job | Purpose | Frequency |
|-----|---------|-----------|
| `RecountAssignedJob` | Recompute `assigned_count` from confirmed submissions | Hourly |
| `ParticipationTotalsJob` | Verify `total_points` matches sum of task points | Daily |
| `EligibilityDriftJob` | Recompute eligibility for recently changed grades | After grade changes |
| `OrphanTaskPointsJob` | Detect task points with missing participation/task | Weekly |
| `RosterIntegrityJob` | Check roster user counts vs. capacities | Daily |

---

## 9. Idempotency Patterns

| Operation | Idempotency Strategy |
|-----------|---------------------|
| `Campaign.finalize!` | Check `status != :finalized` before proceeding |
| `materialize_allocation!` | Replace entire roster (not additive) |
| `GradeScheme::Applier.apply!` | Compare `version_hash`; skip if unchanged |
| `ExamEligibility::ComputationService.compute!` | Upsert pattern preserves overrides |
| `Roster::MaintenanceService` operations | Each operation atomic with validation |

---

## 10. Security & Authorization

```admonish warning "Access Control"
These rules must be enforced via authorization layer (e.g., Pundit policies):
```

| Resource | Permission | Enforcement |
|----------|------------|-------------|
| Campaigns | Create/modify | Staff only |
| Policies | Create/modify | Staff only |
| Submissions | Create | User for self, open campaign |
| Rosters | Modify | Staff only via `MaintenanceService` |
| Grades | Enter/modify | Staff/tutors only |
| Eligibility overrides | Set | Staff only with audit trail |

---

## 11. Monitoring & Alerts

### Key Metrics

```admonish tip "Recommended Alerts"
Set up monitoring for these conditions:
```

| Metric | Threshold | Action |
|--------|-----------|--------|
| Orphan submissions (missing `registration_item`) | = 0 | Alert immediately |
| Allocation failures in last 24h | > 0 | Alert staff |
| Drift: `|assigned_count - confirmed_count|` | > 5 per item | Trigger recount job |
| Eligibility computation age | > 24h during registration | Alert staff |
| MC threshold computation failures | > 0 | Alert immediately |
| Task points exceeding max points | > 0 | Alert graders |

---

## 12. Audit Checklist

Use this checklist for manual verification:

- [ ] Random sample: confirmed submission IDs match roster user IDs (for recently finalized campaigns)
- [ ] Random sample: `total_points` matches `sum(task_points.points)` for assessments
- [ ] All eligibility overrides have non-null `override_reason`
- [ ] Registration policy `position` values are continuous (no gaps) per campaign
- [ ] No MC tasks exist for non-exam assessments
- [ ] All MC tasks have associated grade schemes
- [ ] Roster changes have audit trail entries
- [ ] No orphan task points (all reference valid participation + task)

