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

### Soft-Delete Registrations via `excluded` Status (HIGH PRIORITY)

**Current State:** "Remove registrations" (`destroy_for_user`) performs a hard `destroy_all`, permanently deleting all `UserRegistration` rows for a user in a campaign. This leaves no trace that a registration ever existed, even though `materialized_at` was designed as a permanent record.

**Proposed Enhancement:** Add `excluded: 3` to the `UserRegistration` status enum. Instead of deleting rows, transition them to `excluded`. This preserves the registration history for auditing and traceability.

**Impact analysis (8 must-change, ~11 review):**

Must change:
1. `UserRegistration` — add `excluded: 3` to enum
2. `UserRegistrationsController#destroy_for_user` — transition to `:excluded` instead of `destroy_all`
3. `AllocationService#reset_registrations` — add `.where.not(status: :excluded)`
4. `AllocationService#allocate!` forced-registration cleanup — protect excluded rows from `delete_all`
5. `Campaign#rejected_count` — filter must account for excluded
6. EN/DE locale files — add status translation (`"Excluded"` / `"Ausgeschlossen"`)
7. Factory — add `:excluded` trait
8. Status color helper — add color for excluded (gray/dark)

Review (semantic decisions):
- `total_registrations_count`: should excluded inflate the total? (likely no)
- `pending_count`: could double-count users with both pending + excluded rows
- `AllocationDashboard#calculate_conflicts`: unfiltered `pluck(:user_id)` includes excluded
- `_overview.html.erb`: whether to show excluded count to admins
- Counter cache: `update_all` skips callbacks, so either use individual `update!` (fine for single-user admin action) or manually recalculate `confirmed_registrations_count`

Safe (no changes needed): `FinalizationGuard` (only iterates `.confirmed`), `PolicyEngine` (evaluates user, not status), `Registerable` (no status references), `Campaign#finalize!` (only touches `.pending`).

**Complexity:** Medium. Touches many files but each change is small. The main risk is counter cache consistency when switching from `destroy_all` to status transitions.

- **Roster membership policy (`on_roster`)**: Restrict registration to users on a specific lecture/course roster. Alternative to campaign chaining via `prerequisite_campaign` policy (e.g., seminar talk registration restricted to students on seminar enrollment roster). Config: `{ "roster_source_id": <lecture_id> }`. Check: `source.roster.include?(user)`.
- **Item-level capacity**: Add `capacity` column to `registration_items` to enable capacity partitioning across campaigns (e.g., same tutorial in two campaigns with split capacity: 20 seats for CS students, 10 for Physics). Items have independent capacity from domain objects. Soft validation warns if `sum(items.capacity) > tutorial.capacity`.
- **Asynchronous Allocation (`:calculating` status)**: When moving the allocation solver to a background job, introduce a `:calculating` status to lock the campaign during execution. This distinguishes "solver running" (locked) from "results ready for review" (`:processing`, unlocked for adjustments).
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
- Automatic load ### Full Trace for Policy Evaluation

**Context:** The current policy engine stops at the first failure (`eligible?` returns false immediately).

**Proposed Enhancement:** Implement a `full_trace` method that evaluates all policies and returns all failures.

**Reference:** [Original Implementation Draft](https://github.com/MaMpf-HD/mampf/blob/4e06fc07ead65e05b11a30f7c1a3a4ec7eab91c5/app/services/registration/policy_engine.rb#L36-L47)

**Reasoning:**
For a student, it might be beneficial to see all reasons for ineligibility at once. Currently, if they fix one violation (e.g., "Policy X violated"), they might immediately encounter the next one ("Policy Y violated"). A full trace allows them to resolve all issues in parallel.

---

### Other Registration Extensions

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

### Relaxed Policy Freezing

**Current State:** All policies are frozen once a campaign leaves the `draft` state.

**Proposed Enhancement:** Allow adding or editing policies with `phase: :finalization` even when the campaign is `open`.

**Rationale:**
Finalization policies (e.g., "Min/Max Credits") are only evaluated during the allocation algorithm and do not affect a student's ability to register. Changing them mid-flight does not invalidate existing registration records.

**Implementation Challenges:**
Requires conditional UI logic to show the "Add Policy" button but restrict the form to only allow the `finalization` phase, preventing accidental addition of `registration` policies which *must* remain frozen.

---

- **Roster membership policy (`on_roster`)**: Restrict registration to users on a specific lecture/course roster. Alternative to campaign chaining via `prerequisite_campaign` policy (e.g., seminar talk registration restricted to students on seminar enrollment roster). Config: `{ "roster_source_id": <lecture_id> }`. Check: `source.roster.include?(user)`.
- **Item-level capacity**: Add `capacity` column to `registration_items` to enable capacity partitioning across campaigns (e.g., same tutorial in two campaigns with split capacity: 20 seats for CS students, 10 for Physics). Items have independent capacity from domain objects. Soft validation warns if `sum(items.capacity) > tutorial.capacity`.
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

### Monotonic Unassigned Count on Dissolved Campaign Pills

**Current State:** After finalization, the dissolved campaign pill shows the number of unassigned registrants via `Campaign#unassigned_users`. This is a live query: it checks which campaign registrants (including rejected ones, intentionally — teachers need to see students who didn't get a spot) are currently not on any roster of the relevant type lecture-wide. The count can go up if a teacher removes a student from a group and doesn't place them elsewhere.

**Desired Behavior:** Once a teacher acts on an unassigned student (e.g. manually placing them into a group via the panel), that student should be considered "handled" permanently. Later roster moves (removing the student again, transferring to a different group) should not re-increase the unassigned count. The count should only ever decrease.

**Proposed Implementation:** Add an `ever_rostered` boolean column (default `false`) to `registration_user_registrations`. Set it to `true`:
- During `finalize!` for all confirmed registrations (the materializer already places them on rosters).
- Via callback on roster entry creation (`TutorialMembership`, `SpeakerTalkJoin`, etc.) when the user has registrations in completed campaigns.

Change `Campaign#unassigned_users` to filter out users whose registrations all have `ever_rostered = true`.

**Trade-offs:**
- Introduces cross-domain coupling: roster layer must update registration records.
- Write-once flag (false → true) minimizes consistency risk.
- Migration is small: one boolean column + index.

**Complexity:** Low-Medium.

### Generic Registration Groups (Lightweight Rosterables)

**Problem:** Currently, `Tutorial` is the primary unit for registration. This forces users to create "fake tutorials" for simple use cases like "Lecture Admission" (where no tutorials exist) or "Event Registration" (e.g., Faculty Barbecue).

**Proposed Solution:** Introduce a `Cohort` model (contained within a generic `Grouping`) that acts as a lightweight container.

**New Models:**
1.  **`Cohort` (The Bucket):**
    - **Concerns:** `Registration::Registerable`, `Rosters::Rosterable`.
    - **Attributes:** `capacity`, `title`.
    - **Polymorphic Parent:** Belongs to `context` (Lecture, Offering, etc.).
    - **No Scheduling:** No tutors, rooms, or time slots.

2.  **`Grouping` (The Context):**
    - **Role:** Acts as the generic `campaignable` for non-academic scenarios (events, polls, organizational tasks).
    - **Attributes:** `title`, `description`.
    - **Associations:** `has_one :campaign`, `has_many :cohorts`.
    - **Examples:**
        - **Event:** "Faculty Barbecue" containing cohorts "Meat", "Vegetarian".
        - **Poll:** "New Building Name" containing cohorts "Turing Hall", "Noether Hall".

**Benefits:**
- Decouples registration from academic scheduling.
- Simplifies UI for non-tutorial use cases.
- Reuses existing `MaintenanceController` and `Allocation` logic.

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

## 5. Student Performance & Certification

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

## 11. Assessment System Extensions

### Assessment-Based Submissions (Unified Grading Integration)

**Current State:** Submissions are tightly coupled to the `Assignment` model via `assignment_id`. Only assignments support file uploads.

**Limitation:** To support submissions for exams (scanned answer sheets) or talks (presentation slides), we'd need to keep adding more foreign keys or create separate submission models.

**Proposed Enhancement:** Link submissions directly to `Assessment::Assessment` instead of polymorphic domain models.

**Motivation:**
- **Exam submissions:** Upload scanned answer sheets after in-person exam
- **Talk submissions:** Upload presentation slides before/after seminar talk
- **Lab reports, project deliverables, etc.**
- **Unified grading:** Submissions already flow to `TaskPoint` records through Assessment
- **Simpler architecture:** Single foreign key instead of polymorphic associations
- **Consistent with existing patterns:** `TaskPoint` already uses `assessment_id`

**Why `assessment_id` instead of polymorphic `submissible`?**

Every Assignment/Exam/Talk that accepts submissions already has an `Assessment::Assessment` record (created via `Assessable` concern). We leverage this existing relationship:

```ruby
Submission → Assessment → Assessable (Assignment/Exam/Talk)
```

**Implementation:**

```ruby
# Migration: Replace assignment_id with assessment_id
class ReplaceAssignmentIdWithAssessmentId < ActiveRecord::Migration[7.2]
  def up
    add_column :submissions, :assessment_id, :uuid
    add_foreign_key :submissions, :assessment_assessments, column: :assessment_id
    add_index :submissions, :assessment_id

    # Make tutorial_id nullable (not all submissions need it)
    change_column_null :submissions, :tutorial_id, true

    # Backfill existing submissions
    execute <<-SQL
      UPDATE submissions
      SET assessment_id = assessment_assessments.id
      FROM assignments
      INNER JOIN assessment_assessments
        ON assessment_assessments.assessable_type = 'Assignment'
        AND assessment_assessments.assessable_id = assignments.id
      WHERE submissions.assignment_id = assignments.id
    SQL

    # Verify backfill before dropping
    # remove_column :submissions, :assignment_id
  end

  def down
    change_column_null :submissions, :tutorial_id, false
    remove_column :submissions, :assessment_id
  end
end

# Update Submission model
class Submission < ApplicationRecord
  belongs_to :assessment, class_name: "Assessment::Assessment"
  belongs_to :tutorial, optional: true  # Only for assignments

  # Convenience method for accessing domain object
  def submissible
    assessment.assessable  # Returns Assignment, Exam, or Talk
  end

  # Domain-specific methods updated
  def in_time?
    deadline = case submissible
    when Assignment then submissible.deadline
    when Exam then submissible.held_at
    when Talk then submissible.date
    end
    (last_modification_by_users_at || created_at) <= deadline
  end

  # Validation updated for optional tutorial
  def matching_lecture
    return true unless tutorial  # Skip for exam/talk submissions
    return true if tutorial.lecture == submissible.lecture

    errors.add(:tutorial, :lecture_not_matching)
  end
end
```

**Tutorial Context:**

The `tutorial_id` column is assignment-specific and should be nullable:

- **Assignment submissions:** `tutorial_id` is populated (student's tutorial context)
- **Exam submissions:** `tutorial_id` is `nil` (exams aren't tied to tutorials)
- **Talk submissions:** `tutorial_id` is `nil` (the talk itself is the rosterable unit)

**Why keep `tutorial_id` at all?**

For assignments, it provides:
1. **Performance:** Fast queries like "all submissions for Tutorial X"
2. **Context:** Which tutorial/tutor graded the submission
3. **Disambiguation:** For cross-tutorial teams, which tutorial "owns" the grading

For exam/talk submissions, this context doesn't apply, so the column remains null.

**Submissible Concern (Provides Submissions Association):**

The concern gives assessable models access to their submissions:

```ruby
# app/models/assessment/submissible.rb
module Assessment
  module Submissible
    extend ActiveSupport::Concern

    included do
      # Access submissions through assessment
      has_many :submissions, through: :assessment,
        class_name: "Submission"
    end

    # Helper methods provided by the concern
    def has_submissions?
      submissions.any?
    end

    def proper_submissions
      submissions.where.not(manuscript_data: nil)
    end

    def submission_count
      submissions.count
    end

    def accepts_team_submissions?
      lecture&.submission_max_team_size.to_i > 1
    end
  end
end

# Usage in models
class Assignment < ApplicationRecord
  include Assessment::Pointable
  include Assessment::Submissible  # Provides has_many :submissions
end

class Exam < ApplicationRecord
  include Assessment::Pointable
  include Assessment::Gradable
  include Assessment::Submissible  # Provides has_many :submissions for scanned answer sheets
end

class Talk < ApplicationRecord
  include Assessment::Gradable
  include Assessment::Submissible  # Provides has_many :submissions for presentation slides
end
```

**Assessment Model Update:**

The Assessment model needs the reverse association:

```ruby
class Assessment::Assessment < ApplicationRecord
  belongs_to :assessable, polymorphic: true
  has_many :submissions, dependent: :destroy  # Add this
  has_many :assessment_participations, dependent: :destroy
  # ...
end
```

Now models can access submissions easily:

```ruby
assignment.submissions         # Works via Submissible concern
assignment.assessment.submissions  # Also works (direct path)
```

**Controller Changes:**

```ruby
# Current (assignment-only):
@submission = Submission.new(assignment_id: params[:assignment_id])

# Assessment-based (works for any type):
assignment = Assignment.find(params[:assignment_id])
@submission = Submission.new(assessment: assignment.assessment)

# Or for exams:
exam = Exam.find(params[:exam_id])
@submission = Submission.new(assessment: exam.assessment)
```

**View Changes:**

```erb
<!-- Current: -->
<%= submission.assignment.title %>
<%= link_to "Assignment", assignment_path(submission.assignment) %>

<!-- Assessment-based: -->
<%= submission.submissible.title %>
<%= link_to submission.submissible.class.name, polymorphic_path(submission.submissible) %>

<!-- Or with helper: -->
<%= submission.assessment.title %>  <!-- Delegated to assessable -->
<%= link_to_assessable(submission.assessment) %>
```

**Benefits:**
- **Simpler:** Single foreign key, no polymorphic associations
- **Consistent:** Matches existing `TaskPoint.assessment_id` pattern
- **Grading-ready:** Direct path from Submission → Assessment → TaskPoint
- **Less refactoring:** No need to update polymorphic routes/controllers
- **Works for all types:** Assignment/Exam/Talk submissions unified

**Required Changes:**
- Migration: Add `assessment_id`, backfill from `assignment_id` via Assessment lookup
- Model: Update methods that reference `assignment` to use `submissible` helper
- Views: Replace `submission.assignment` with `submission.submissible`
- Controllers: Build submissions via `assessment` instead of `assignment_id`

**Complexity:** Medium
- Schema migration with backfill required
- Model method updates for deadline/expiration logic
- View updates for display and navigation
- Controllers need assessment lookup logic

**Testing Strategy:**
- Ensure all existing assignment submissions work unchanged
- Add specs for exam submissions (when implemented)
- Add specs for talk submissions (when implemented)
- Integration tests for submission → grading workflow

**Timeline:** Post-MVP. Current state (assignment-only submissions via `assignment_id`) is sufficient for initial release. Implement when exam submissions or talk submissions become a concrete requirement.

**Related:** See [Submission Model](04-assessments-and-grading.md#submission-extended-model) for current implementation.

---

## 12. Security & Compliance

- Policy audit trail (tamper-evident logs)
- PII minimization (anonymize exports, configurable retention)
- GDPR compliance (data export, deletion, consent management)

---

## 13. Developer Experience

- Reference seed script (generate realistic test data)
- Scenario generator (complex allocation/grading scenarios)
- Solver visualizer (export flow network to DOT/Mermaid)
- Benchmark harness (compare algorithm performance)
- Documentation sync (CI check for broken mdbook links)

---

## 13. Developer Experience

- Reference seed script (generate realistic test data)
- Scenario generator (complex allocation/grading scenarios)
- Solver visualizer (export flow network to DOT/Mermaid)
- Benchmark harness (compare algorithm performance)
- Documentation sync (CI check for broken mdbook links)

---

## 14. UI/UX

- Real-time capacity counters (WebSocket updates)
- Drag-drop preference ordering with validation
- Grade histogram overlay (scheme preview)

---

## 15. Migration & Cleanup

- Dual-write (new + legacy systems)
- Backfill historical data
- Read switch with parity monitoring
- Remove deprecated code/columns
- Legacy eligibility flags cleanup
- Manual roster seeding code removal
- Obsolete submission routing cleanup

---

## 15. Migration & Cleanup

- Dual-write (new + legacy systems)
- Backfill historical data
- Read switch with parity monitoring
- Remove deprecated code/columns
- Legacy eligibility flags cleanup
- Manual roster seeding code removal
- Obsolete submission routing cleanup

---

## 16. Research Opportunities

- Fairness metrics (study allocation algorithm properties)
- Optimal grading curves (per-subject analysis)
- Predictive modeling (early intervention for at-risk students)
- Learning analytics (engagement vs. outcomes correlation)

---

## 17. Full Trace for Policy Evaluation

(Moved to Section 2: Registration & Policy System)
