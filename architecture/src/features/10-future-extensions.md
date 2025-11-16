# Future Extensions & Roadmap

Collection of potential enhancements and ideas for future development.

```admonish note "Implementation Status"
The core architecture documented in Chapters 1-9 represents the planned baseline. This chapter lists potential future enhancements.
```

---

## 1. Allocation Algorithm

- CP-SAT strategy (fairness tiers, exclusions, group pairing)
- Soft penalties (time-of-day preferences, instructor load balancing)
- Diversity/quota constraints (track distribution, campus location)
- Multi-round capacity release (phased seat allocation)
- Waitlist modeling (flow network with priority costs)
- Multi-campaign global optimization (joint tutorial + lab balancing)
- Solver audit trail (persist inputs/outputs as JSON for debugging)
- Alternative algorithm comparison (min-cost flow vs. CP-SAT benchmarks)

---

## 2. Registration & Policy System

### Scheduled Campaign Opening

**Current State:** Campaigns require manual teacher action to transition `draft → open`.

**Proposed Enhancement:** Automatic opening via background job.

**Implementation:**
```ruby
add_column :registration_campaigns, :registration_start, :datetime

# Validation
validates :registration_start, presence: true
validate :start_before_deadline

# Background job (every 5 minutes)
Registration::CampaignOpenerJob.perform_async
  Registration::Campaign.where(status: :draft)
    .where("registration_start <= ?", Time.current)
    .find_each(&:open!)
end
```

**Benefits:**
- Symmetry: auto-open + auto-close provides full automation
- Teacher workflow: set up campaign in advance, forget about it
- Reduces manual intervention during high-traffic registration windows

**Trade-offs:**
- Adds complexity (another background job, another timestamp)
- Teachers lose last-minute verification opportunity before going live
- Current manual flow forces review before opening

**Recommendation:** Defer to post-MVP. Current workaround (manual open) is acceptable. Implement if teachers report frequent "forgot to open" incidents during beta testing.

**Complexity:** Low (additive change, no schema conflicts)

**References:** See [Registration - Campaign Lifecycle](02-registration.md#campaign-lifecycle-state-diagram)

---

### Other Registration Extensions

- Policy trace persistence (store evaluation results for audit)
- User-facing explanations (API endpoint showing why ineligible)
- Rate limiting for FCFS hotspots
- Bulk eligibility preview (matrix: users × policies)
- Policy simulation mode (test changes without affecting real data)
- Automated certification proposals (ML-based predictions from partial semester data)
- Certification templates (pre-fill common override scenarios)
- Certification bulk operations (approve/reject multiple students at once)

---

## 3. Roster Management

- Batch operations (CSV import/export)
- Capacity forecasting and rebalancing suggestions
- Automatic load balancing (heuristic-based)
- Enhanced change history UI

---

## 4. Assessment & Grading

### Submission Support for Exams and Talks

```admonish info "Current Status"
Currently, file submissions are only implemented for **Assignment** types. The underlying data model (`Submission` with `assessment_id` field) was designed to support submissions for all assessment types, but the UI and workflows are scoped to assignments only.
```

**Use Cases for Future Extension:**

| Assessment Type | Submission Scenario | Example |
|-----------------|---------------------|---------|
| Exam (Online) | Students upload completed exam PDFs | Take-home exam, timed online exam |
| Exam (In-Person) | Staff upload scanned answer sheets | Physical exam digitized for archival/grading |
| Talk | Speakers upload presentation materials | Slides, handouts, supplementary files |

**Infrastructure Ready:**
- ✅ `Submission` model uses `assessment_id` (supports any assessment type)
- ✅ `Assessment::Assessment` has `requires_submission` boolean field
- ✅ `Assessment::Participation` tracks `submitted_at` timestamp
- ✅ `Assessment::TaskPoint` can link to `submission_id` for audit trails

**Requirements for Implementation:**
- Design submission UI adapted for exam/talk contexts (different from assignment task-based interface)
- Adapt grading workflows (exam submissions may need different grading patterns than assignment tasks)
- Consider timing constraints (exam time windows, talk presentation schedules)
- Define file type restrictions (exam PDFs vs presentation formats)
- Handle team vs individual submissions (talks may have co-presenters)

**Complexity:** Medium (model foundation exists, need UI and workflow design)

**References:** See [Assessments & Grading - Submission Model](04-assessments-and-grading.md#submission-extended-model)

---

### Task-Wise Grading (Optional Workflow)

```admonish info "Current Status"
The default grading workflow is **tutorial-wise**: each tutor grades all tasks for their own tutorial's submissions. The data model already supports an alternative workflow where grading is distributed by task instead of by tutorial, but this requires additional UI and configuration features.
```

**Use Case:**

By default, tutors grade all tasks for their own tutorial's submissions. An alternative workflow is **task-wise grading**, where each tutor specializes in grading a specific task across all tutorials.

| Traditional (Tutorial-Wise) | Task-Wise Alternative |
|----------------------------|----------------------|
| Tutorial A tutor: grades Tasks 1-3 for 30 students | Tutor 1: grades Task 1 for all 60 students |
| Tutorial B tutor: grades Tasks 1-3 for 30 students | Tutor 2: grades Task 2 for all 60 students |
| Each tutor: 90 gradings (30 × 3) | Tutor 3: grades Task 3 for all 60 students |
| | Each tutor: 60 gradings (specialization) |

**Benefits:**
- **Consistency:** Same tutor grades same problem for everyone (reduces grading variance)
- **Efficiency:** Tutor becomes expert in one problem, grades faster with practice
- **Fairness:** Eliminates "tough tutor vs. lenient tutor" differences per task
- **Specialization:** Complex problems assigned to most experienced tutor

**Infrastructure Already in Place:**
- ✅ `Assessment::TaskPoint` has `grader_id` (can be any tutor)
- ✅ `Submission` has `tutorial_id` for context but grading isn't restricted by it
- ✅ `Assessment::SubmissionGrader` accepts any `grader:` parameter

**Requirements for Implementation:**

1. **Data Model Addition:**
   - New model: `Assessment::TaskAssignment` linking `task_id` → `tutor_id`
   - New enum on `Assessment::Assessment`: `grading_mode` (`:tutorial_wise` default, `:task_wise`)
   - Migration for `assessment_task_assignments` table

2. **Teacher Interface:**
   - Assessment show page: grading mode selector
   - When task-wise selected: UI to assign each task to a tutor
   - Progress dashboard showing per-task completion across all tutorials

3. **Modified Tutor Grading Interface:**
   - Filter submissions by assigned tasks (not just by tutorial)
   - Show all tutorials' submissions for assigned tasks
   - Progress: "45/89 students graded for Task 1"
   - Maintain existing grading UI, just change data scope

4. **Controller Logic:**
   ```ruby
   if @assessment.task_wise?
     @tasks = @assessment.tasks
       .joins(:task_assignments)
       .where(assessment_task_assignments: { tutor_id: current_user.id })
     @submissions = @assessment.submissions  # all tutorials
   else
     @tasks = @assessment.tasks  # all tasks
     @submissions = @tutorial.submissions  # current tutorial only
   end
   ```

5. **Publication Control:**
   - Recommend teacher-level publication when all tasks complete
   - Per-tutorial publication doesn't make sense in task-wise mode
   - Could offer per-task publication as alternative

**Edge Cases to Handle:**
- Reassignment mid-grading: keep existing `grader_id` on TaskPoints (historical record)
- Cross-tutorial teams: team submission appears once, graded by task-assigned tutor
- Mixed mode: initially all-or-nothing (can't mix modes per task)

**Complexity:** Medium (model support exists, need UI and workflow adaptation)

**References:** See [Assessments & Grading - TaskPoint Model](04-assessments-and-grading.md#assessmenttaskpoint-activerecord-model) for `grader_id` field

---

### Other Assessment Extensions

- Inline annotation integration (external service)
- Rubric templates per task (structured criteria + auto-sum)
- Late policy engine (configurable penalty computation)
- Task dependencies (unlock logic)
- Peer review workflows

### Grading Audit Trail (Teacher Override Tracking)

**Use Case:** Track when teachers modify points after initial grading (e.g., complaint handling).

**Current State:**
- `Assessment::TaskPoint` has `grader_id` and `graded_at`
- No explicit tracking of modifications after initial grading
- Cannot distinguish "teacher graded initially" from "teacher overrode tutor grade"

**Implementation:**

Add modification tracking fields:
```ruby
add_column :assessment_task_points, :modified_by_id, :integer
add_column :assessment_task_points, :modified_at, :datetime
add_index :assessment_task_points, :modified_by_id
```

**Logic:**
- Initially: `grader_id` = tutor, `modified_by_id` = nil
- Teacher edits: `modified_by_id` = teacher, `modified_at` = Time.current
- Keep original `grader_id` for audit trail

**Benefits:**
- Explicit tracking of override events
- Preserves original grader context
- Enables audit reports ("all teacher overrides for this assessment")
- Simple to query and display in UI

**UI Indicators:**
- Warning icon on modified cells
- Tooltip: "Modified by [Teacher Name] on [Date]"
- Teacher grading details view shows "Last Changed" column

### Multiple Choice Extensions

- MC question bank (reusable question library)
- Randomized exams (per-student variants)
- Statistical analysis (item difficulty, discrimination indices)

---

## 5. Lecture Performance & Certification

```admonish success "Recently Implemented"
The core certification workflow (teacher-approved eligibility decisions, Evaluator proposals, pre-flight checks) is now part of the baseline architecture documented in Chapter 5.
```

**Future Extensions:**

- Multiple concurrent certification policies (AND/OR logic expression builder)
- Incremental recompute (listen to grade changes, auto-update stale certifications)
- Student-facing certification preview (before registration opens, show provisional status)
- Custom formula DSL (complex eligibility calculations beyond simple point thresholds)
- Certification history (track changes over time, audit teacher decisions)
- Automated ML proposals (predict eligibility from partial semester data)
- Bulk certification UI (approve/reject multiple students with filters)
- Certification analytics (pass rate trends, override frequency analysis)

---

## 6. Grade Schemes

- Percentile buckets (automatic equal-size grouping)
- Curve normalization (mean target, standard deviation scaling)
- Piecewise linear editor with live histogram preview
- Custom function DSL (arbitrary grade computations)
- Course-level aggregation (weighted composition across assessments)
- Pass/fail rules (configurable requirements)
- Bonus points system (extra credit with caps)

---

## 7. Analytics & Reporting

- Student grade projection ("what if" calculator)
- Progress tracking dashboard
- Historical trend comparison
- Allocation satisfaction metrics (average preference rank achieved)
- Grade distribution analysis (variance heatmaps, outliers)
- Capacity utilization tracking
- Tutor workload reports
- CSV export with snapshot versioning
- JSON API (read-only endpoints)
- Materialized views for performance

---

## 8. Operational Tools

- Automatic integrity auditor (scheduled job checking invariants)
- Integrity dashboard (real-time constraint violations)
- Performance metrics (query times, job durations, failure rates)
- mdBook link checker CI integration
- Chaos testing (inject perturbations in test environment)
- Solver visualizer (export flow network to DOT/Mermaid)
- Benchmark harness (compare algorithm performance)

---

## 9. Performance & Scalability

- Incremental solver updates (delta changes for preference edits)
- Eligibility caching (memoize with versioned keys)
- Points total caching (invalidate per TaskPoint write)
- Database sharding strategy

---

## 10. API & Extensibility

- GraphQL endpoint (read-only access to allocations/grades)
- REST API (standard CRUD for integrations)
- Webhooks (events: finalize, grade published, eligibility change)
- Internal event bus (decouple reactions)
- Plugin system (custom policy types, grade schemes)

---

## 11. Security & Compliance

- Policy audit trail (tamper-evident logs)
- PII minimization (anonymize exports, configurable retention)
- GDPR compliance (data export, deletion, consent management)

---

## 12. Developer Experience

- Reference seed script (generate realistic test data)
- Scenario generator (complex allocation/grading scenarios)
- Solver visualizer (export flow network to DOT/Mermaid)
- Benchmark harness (compare algorithm performance)
- Documentation sync (CI check for broken mdbook links)

---

## 13. UI/UX

- Real-time capacity counters (WebSocket updates)
- Drag-drop preference ordering with validation
- Grade histogram overlay (scheme preview)

---

## 14. Migration & Cleanup

- Dual-write (new + legacy systems)
- Backfill historical data
- Read switch with parity monitoring
- Remove deprecated code/columns
- Legacy eligibility flags cleanup
- Manual roster seeding code removal
- Obsolete submission routing cleanup

---

## 15. Research Opportunities

- Fairness metrics (study allocation algorithm properties)
- Optimal grading curves (per-subject analysis)
- Predictive modeling (early intervention for at-risk students)
- Learning analytics (engagement vs. outcomes correlation)
