# Implementation PR Roadmap

This chapter breaks down the Registration system into small, reviewable
pull requests. It complements the Implementation Plan with
concrete PR scopes, dependencies, and acceptance criteria.

```admonish info
Guiding principles:
- Keep PRs tight and shippable behind feature flags.
- Prefer vertical slices that produce visible value.
- Add tests and docs incrementally with each PR.
```

```admonish tip
Plan ↔ PR crosswalk (Registration workstream):
- Step 2 — Foundations (schema/backend): PR-2.x
- Step 3 — FCFS mode (admin + student): PR-3.x
- Step 4 — Preference-based mode (student + allocation): PR-4.x
- Step 5 — Roster maintenance: PR-5.x
```

```admonish abstract
Registration — Step 2: Foundations (Schema)
```

```admonish example "PR-2.1 — Schema and core models"
- Scope: AR models `Registration::Campaign`, `Item`, `UserRegistration`,
    `Policy` and additive migrations.
- Migrations:
    - `20251028000000_create_registration_campaigns.rb`
    - `20251028000001_create_registration_items.rb`
    - `20251028000002_create_registration_user_registrations.rb`
    - `20251028000003_create_registration_policies.rb`
- Refs: Models — [Campaign](02-registration.md#registrationcampaign-activerecord-model),
  [Item](02-registration.md#registrationitem-activerecord-model),
  [UserRegistration](02-registration.md#registrationuserregistration-activerecord-model),
  [Policy](02-registration.md#registrationpolicy-activerecord-model)
- Acceptance: Migrations run cleanly; models have correct associations and validations; no existing tables altered.
```

```admonish example "PR-2.2 — Policy engine (institutional_email, prerequisite_campaign)"
- Scope: `Registration::PolicyEngine` with two policy kinds.
- Implementation: `Registration::PolicyEngine#evaluate_policies_for`,
  `Registration::Policy#evaluate` for `institutional_email` and
  `prerequisite_campaign` kinds.
- Test doubles: Tests use doubles for checking roster membership in
  prerequisite campaigns.
- Refs: [PolicyEngine](02-registration.md#registrationpolicyengine-service),
  [Policy#evaluate](02-registration.md#policy-evaluation-interface)
- Acceptance: Policy engine evaluates ordered policies with short-circuit; tests pass with doubled roster data; `student_performance` policy kind deferred to Step 11.
```

```admonish example "PR-2.3 — Core concerns (Campaignable, Registerable)"
- Scope: Include `Registration::Campaignable` in `Lecture` and
  `Registration::Registerable` in `Tutorial`.
- Implementation:
  - `Campaignable`: `has_many :registration_campaigns, as: :campaignable`
  - `Registerable`: `capacity`, `allocated_user_ids` (raises NotImplementedError),
    `materialize_allocation!` (raises NotImplementedError)
- Refs: [Campaignable](02-registration.md#registrationcampaignable-concern),
  [Registerable](02-registration.md#registrationregisterable-concern)
- Acceptance: Tutorial includes Registerable; methods raise NotImplementedError when called; no functional changes to existing semester.
```

```admonish example "PR-2.4 — Seminar/Talk support (Optional, can defer post-MVP)"
- Scope: Include `Registration::Campaignable` in `Seminar` and
  `Registration::Registerable` in `Talk`.
- Same pattern as PR-2.3 but for seminars.
- Refs: Same concerns, different models.
- Acceptance: Same as PR-2.3 for seminar context.
```

```admonish abstract
Registration — Step 3: FCFS Mode
```

```admonish example "PR-3.1 — Admin: Campaigns scaffold (CRUD + open/close)"
- Scope: Teacher/editor UI for campaign lifecycle (draft → open → closed → processing → completed).
- Controllers: `Registration::CampaignsController` (new/create/edit/update/show/destroy).
- Actions: `open` (validates policies, updates status to :open), `close` (background job triggers status → :closed), `reopen` (reverts to :open if allocation not started).
- Freezing: Campaign-level attributes freeze on lifecycle transitions (`allocation_mode`, `registration_opens_at` after draft; policies freeze on open).
- UI: Turbo Frames for inline editing; flash messages for validation errors and freeze violations; feature flag `registration_campaigns`; disabled fields for frozen attributes.
- Refs: [Campaign lifecycle & freezing](02-registration.md#campaign-lifecycle--freezing-rules),
  [State diagram](02-registration.md#campaign-state-diagram)
- Acceptance: Teachers can create draft campaigns, add policies, open campaigns (with policy validation); campaigns cannot be deleted when open/processing; freezing rules enforced with clear error messages; frozen fields disabled in UI; feature flag gates UI.
```

```admonish example "PR-3.2 — Admin: Items CRUD (nested under Campaign)"
- Scope: Manage registerable items within a campaign, including cohorts.
- Controllers: `Registration::ItemsController` (nested routes under campaigns).
- Freezing: Items cannot be removed when `status != :draft` (prevents invalidating existing registrations); adding items always allowed.
- UI: Turbo Frames for inline item addition/removal; capacity editing; delete button disabled for items when campaign is open.
- Refs: [Item model](02-registration.md#registrationitem-activerecord-model),
  [Freezing rules](02-registration.md#campaign-lifecycle--freezing-rules)
- Acceptance: Teachers can add items anytime; items cannot be removed if campaign is open or has registrations for that item; capacity edits validated.
```

```admonish example "PR-3.3 — Student: Register (single-item FCFS)"
- Scope: Student registration for single-item campaigns (e.g., one tutorial per lecture).
- Controllers: `Registration::UserRegistrationsController` (create/destroy).
- Logic: FCFS mode with capacity checks; policy evaluation on create.
- Freezing: Item capacity can increase anytime; can decrease only if `new_capacity >= confirmed_count` (prevents revoking confirmed spots).
- UI: Registration button; Turbo Stream updates for immediate feedback; capacity editing validates against confirmed count.
- Refs: [FCFS mode](02-registration.md#fcfs-mode-direct-assignment),
  [Freezing rules](02-registration.md#campaign-lifecycle--freezing-rules)
- Acceptance: Students can register for open campaigns; capacity enforced; policy violations shown with error messages; confirmed status set immediately; capacity decrease blocked if it would revoke spots.
```

```admonish example "PR-3.4 — Student: Register (multi-item FCFS)"
- Scope: Extend PR-3.3 for multi-item campaigns (e.g., tutorial selection from multiple options).
- Controllers: Extend `Registration::UserRegistrationsController` to handle item selection.
- UI: Item selection dropdown; Turbo Stream for dynamic item list updates.
- Refs: [Multi-item campaigns](02-registration.md#multi-item-campaigns)
- Acceptance: Students can select from available items; capacity per item enforced; switching items updates previous registration.
```

```admonish example "PR-3.5 — Admin: Campaign Wizard (Pattern Selector)"
- Scope: "New Campaign" wizard that forces an explicit choice of Registration Pattern.
- Controllers: `Registration::CampaignsController#new` handles `?pattern=` param.
- Logic:
  - **Step 1 (Pattern Selection):** User chooses between:
    - **Group Track (Pattern 1):** Creates "Group Registration" campaign (Tutorials/Talks) + optional "Special Groups" campaign (Cohorts).
    - **Enrollment Track (Pattern 2):** Creates "Course Enrollment" campaign (Lecture).
    - **Mixed Track (Pattern 3):** Creates both (gated by explicit acknowledgement).
  - **Step 2 (Configuration):**
    - For Group Track: Select group source (Tutorials vs Talks), optionally add Cohorts.
    - For Enrollment Track: Confirm Lecture target.
- UI: Modal with 3 distinct choices; "Mixed Track" is visually distinct/gated.
- Acceptance: Wizard guides user through pattern selection; correctly creates 1 or 2 campaigns based on choice; enforces acknowledgement for Mixed Track.
```

```admonish abstract
Registration — Step 4: Preference-Based Mode
```

```admonish example "PR-4.1 — Student: Preference ranking UI"
- Scope: UI for students to rank items by preference.
- Controllers: Extend `Registration::UserRegistrationsController` with `update_preferences` action.
- UI: Drag-and-drop ranking interface; persisted as JSONB array in `preferences` column.
- Refs: [Preference mode](02-registration.md#preference-based-mode)
- Acceptance: Students can rank items; preferences saved; cannot submit incomplete rankings.
```

```admonish example "PR-4.2 — Roster foundations (minimal persistence)"
- Scope: Implement minimal roster persistence for `materialize_allocation!`.
- Models: Add `source_campaign_id` to `tutorial_memberships` join table.
- Concerns: Implement `Roster::Rosterable` with `allocated_user_ids`,
  `materialize_allocation!`, `roster_entries`, `mark_campaign_source!`.
- Implementation in Tutorial: Override `allocated_user_ids` to delegate
  to `roster_user_ids`; implement `materialize_allocation!` using
  `replace_roster!` pattern.
- Refs: [Rosterable concern](03-rosters.md#rosterrosterable-concern),
  [Tutorial implementation](03-rosters.md#tutorial-implementation)
- Acceptance: Tutorial implements Rosterable methods; `materialize_allocation!` replaces roster entries tagged with campaign; `allocated_user_ids` returns current roster user IDs.
```

```admonish example "PR-4.3 — Solver + finalize (integrate allocation engine)"
- Scope: Wire solver and finalize end-to-end.
- Services: `Registration::Allocation::Solver` (delegates to CP-SAT or placeholder greedy), `Registration::FinalizationGuard`.
- Controllers: `Registration::AllocationController` (trigger/retry/finalize actions).
- Background: `AllocationJob` runs solver and updates UserRegistration statuses via Turbo Streams.
- Logic: On finalize, call `FinalizationGuard#check!`, then `materialize_allocation!` for each confirmed user.
- Freezing: Item capacity freezes once `status == :completed` (results published); can be adjusted freely during `draft`, `open`, `closed` states.
- Refs: [Solver](02-registration.md#registrationallocation-namespace),
  [Finalization](02-registration.md#finalization-materialization),
  [Freezing rules](02-registration.md#campaign-lifecycle--freezing-rules)
- Acceptance: Teachers can trigger allocation; results streamed to UI; finalize materializes rosters; capacity changes blocked after completion; unconfirmed users stay in limbo; confirmed users added to rosters via `materialize_allocation!`.
```

```admonish abstract
Registration — Step 5: Roster Maintenance
```

```admonish example "PR-5.1 — Roster maintenance UI (admin)"
- Scope: Post-allocation roster management for Sub-Groups (Tutorial/Cohort).
- Controllers: `Roster::MaintenanceController` (move/add/remove actions).
- Logic: Support `Tutorial`, `Talk` and `Cohort` as rosterable types.
- UI: Roster Overview with detail views for individual groups; candidates panel (unassigned users from campaign); basic capacity enforcement.
- Refs: [Roster maintenance](03-rosters.md#roster-maintenance)
- Acceptance: Teachers can move students between tutorials/talks/cohorts; capacity enforced; candidates panel lists unassigned users; manual add/remove works for groups.
```

```admonish example "PR-5.2 — Lecture Roster Superset (Enrollment Track)"
- Scope: Implement Lecture Roster as the superset of all sub-groups.
- Backend:
  - Implement `Lecture#ensure_roster_membership!`.
  - Update `Tutorial/Talk/Cohort#materialize_allocation!` to propagate users to Lecture.
  - Update `Roster::MaintenanceService` to handle Enrollment/Drop logic (cascading delete).
- UI: "Enrollment" tab in `RosterOverviewComponent` showing all lecture members; "Unassigned" status calculation.
- Refs: [Superset Model](03-rosters.md#the-core-concept-lecture-roster-as-superset), [Enrollment Track](03-rosters.md#b-the-enrollment-track)
- Acceptance: Adding user to tutorial adds them to lecture; Removing from lecture removes from tutorial; Enrollment tab lists all students.
```

```admonish example "PR-5.3 — Self-materialization (backend + admin config)"
- Scope: Add `self_materialization_mode` enum to `Rosterable`; implement permission methods; admin UI for configuration.
- Backend:
  - Migration: Add `self_materialization_mode` enum column to tutorials, talks, cohorts, lectures.
  - Update `Roster::Rosterable` concern with `can_self_add?`, `can_self_remove?`, `self_add!`, `self_remove!`.
  - Validation: Block enabling mode during active campaigns (non-planning, non-completed).
- Admin UI:
  - Add mode selector dropdown to roster management UI (per-group basis).
  - Four options: disabled/add_only/remove_only/add_and_remove.
  - Turbo Frame update on change; validation errors shown inline.
  - Feature flag: `self_materialization_enabled`.
- Refs: [Self-materialization](02-registration.md#self-materialization-direct-roster-access),
  [Rosterable concern](03-rosters.md#rosterrosterable-concern)
- Acceptance: Backend methods work; validation enforced; admin can configure mode per tutorial/cohort/talk; changes blocked with clear error if campaign active; feature flag gates both backend and UI.
```

```admonish example "PR-5.4 — Self-materialization UI (student)"
- Scope: Student-facing join/leave buttons.
- Controllers: `Roster::SelfMaterializationController` (join/leave actions).
- UI:
  - Join/Leave buttons on Tutorial/Cohort/Talk show pages.
  - Turbo Stream updates for roster list.
  - Buttons hidden when mode is `disabled`.
  - Capacity/duplicate guards with error messages.
- Refs: [Self-materialization](02-registration.md#self-materialization-direct-roster-access)
- Acceptance: Students can join/leave when enabled; buttons respect mode settings; capacity enforced; clear error messages for violations; feature flag gates UI.
```

```admonish example "PR-5.5 — Tutor abilities (read-only roster access)"
- Scope: Tutors can view rosters for their assigned groups.
- Abilities: Update CanCanCan to allow read-only roster access for tutors.
- UI: Tutors see Detail view without edit actions.
- Refs: [Abilities](02-registration.md#abilities-registration-cancancan)
- Acceptance: Tutors can view rosters for their tutorials; cannot edit; exams do not show candidates panel.
```

```admonish example "PR-5.6 — Manual add student (from candidates or arbitrary)"
- Scope: Add students to rosters manually.
- Controllers: Extend `Roster::MaintenanceController` with `add_student` action.
- UI: "Add student" button on Overview; search input for arbitrary student addition.
- Refs: [Manual operations](03-rosters.md#manual-operations)
- Acceptance: Teachers can add students from candidates or search; capacity enforced; duplicate prevention.
```

```admonish example "PR-5.7 — Roster change notifications"
- Scope: Email notifications for roster changes affecting students.
- Mailer: `Roster::ChangeMailer` with methods: `added_to_group`, `removed_from_group`, `moved_between_groups`.
- Triggers: Called from `Roster::MaintenanceService`, `Registration::Campaign#finalize!`, and `Roster::SelfMaterializationController`.
- Content: Email includes group name, lecture context, action taken, timestamp; for moves, includes both source and target groups.
- Configuration: Feature flag `roster_notifications_enabled`; teacher toggle per lecture for notification verbosity (all changes vs finalization-only).
- Background: Deliver via `ActionMailer::DeliveryJob` (async).
- Refs: [Roster maintenance](03-rosters.md#roster-maintenance)
- Acceptance: Students receive emails on add/remove/move; emails queued asynchronously; feature flag gates delivery; teachers can configure notification timing per lecture.
```

```admonish example "PR-5.8 — Integrity job (lecture roster superset validation)"
- Scope: Background job to verify lecture roster superset principle.
- Job: `RosterSupersetCheckerJob` validates that `Lecture#roster_user_ids` ⊇ (tutorials + talks + propagating cohorts).roster_user_ids.
- Detection: Identifies users in sub-groups who are missing from lecture roster.
- Monitoring: Logs violations for admin review; potential causes include callback failures, race conditions, or manual database edits.
- Refs: [Superset Model](03-rosters.md#the-core-concept-lecture-roster-as-superset)
- Acceptance: Job runs nightly; reports missing users; no auto-fix (manual review required); clear log format with lecture ID, user IDs, and affected groups.
```

```admonish example "PR-5.9 — Turbo Stream Orchestrator"
- Scope: Extract stream logic from controllers into `Turbo::LectureStreamService`.
- Pattern: Controllers declare "what happened" (e.g., `roster_changed`); service returns appropriate streams.
- Refactor: `TutorialsController`, `CohortsController`, `Registration::CampaignsController`, `Roster::MaintenanceController`.
- Implementation:
  - `Turbo::LectureStreamService` with methods: `roster_changed`, `campaign_changed`, `enrollment_changed`.
  - Each method returns array of turbo streams for all dependent UI components.
  - Controllers call service instead of building streams inline.
- Refs: [Turbo Streams](https://turbo.hotwired.dev/handbook/streams)
- Acceptance: Controllers contain no DOM IDs or partial paths; all cross-tab updates centralized in service; adding new dependent views requires editing only the service.
```

```admonish abstract
Grading — Step 6: Assessment Foundations (Schema)
```

```admonish example "PR-6.1 — Assessment schema (core tables)"
- Scope: Create `assessment_assessments`, `assessment_tasks`,
  `assessment_participations`, `assessment_task_points`.
- Migrations:
  - `20251105000000_create_assessment_assessments.rb`
  - `20251105000001_create_assessment_tasks.rb`
  - `20251105000002_create_assessment_participations.rb`
  - `20251105000003_create_assessment_task_points.rb`
- Refs: [Assessment models](04-assessments-and-grading.md#assessmentassessment-activerecord-model)
- Acceptance: Migrations run; models have correct associations; no existing tables altered.
```

```admonish abstract
Grading — Step 7: Assessment Foundations (Backend & CRUD)
```

```admonish example "PR-7.1 — Assessment backend (Concerns + Integration)"
- Scope: Core assessment concerns plus Assignment/Talk integration.
- Backend:
  - Create `Assessment::Assessable` concern (interface for all assessable types)
  - Create `Assessment::Pointable` concern (for task-based grading: assignments, exams)
  - Create `Assessment::Gradable` concern (for final grade: assignments, exams, talks)
  - Include `Assessable + Pointable + Gradable` in Assignment model (behind feature flag)
  - Include `Assessable + Gradable` in Talk model (behind feature flag)
  - Add `after_create :setup_assessment` hooks
- Feature Flag: `assessment_grading_enabled` (per-lecture)
- Behavior: When enabled, new assignments/talks automatically create Assessment record (participations created lazily)
- Refs: [Assessment::Assessable](04-assessments-and-grading.md#assessmentassessable-concern), [Pointable](04-assessments-and-grading.md#assessmentpointable-concern), [Gradable](04-assessments-and-grading.md#assessmentgradable-concern)
- Acceptance: All three concerns exist; Assignment has all three; Talk has Assessable+Gradable; participations seeded on creation; feature flag gates behavior; old assignments unaffected.
```

```admonish example "PR-7.2 — Assessment CRUD UI (without grading)"
- Scope: Complete assessment management UI without grading interface.
- Controllers: `Assessment::AssessmentsController` (full CRUD), `Assessment::TasksController` (nested CRUD), `Assessment::ParticipationsController` (index only)
- UI:
  - "New Assessment" form (depending on assessable - only for assignments here)
  - Index page (list)
  - Show page with tabs (Overview, Settings, Tasks, Grading)
  - Task management (add/edit/reorder problems)
  - Grading tab shows aggregated progress from roster (expected count from roster, graded count from participations)
- Limitations: No point entry, no grade calculation, no result publication (deferred to PR-8.x)
- Feature Flag: Same `assessment_grading` flag gates entire UI
- Refs: [Assessment controllers](11-controllers.md#assessmentassessmentscontroller), [Views](12-views.md#assessments)
- Acceptance: Teachers can create assessments via UI; grading overview shows progress; tasks configurable; no grading actions available; feature flag gates access.
```

```admonish abstract
Grading — Step 8: Exams, Point/Grade Views & Publication
```

```admonish info
Step 8 is split into a **read-only path** (PRs 8.1, 8.3–8.5) and an
**interactive write path** (PRs 8.2, 8.6–8.9) that can be developed in
parallel by different team members.

The read-only PRs deliver views that display grade and point data
seeded via rake playground tasks. The interactive PRs later add
services and inline editing on top of the same components. This
separation allows the analysis pipeline (Steps 9–12) to proceed
without waiting for the interactive entry UI.
```

```admonish example "PR-8.1 — Exam foundations (backend & teacher UI)"
- Scope: Exam model, backend implementation, teacher CRUD, campaign creation for exams.
- Migrations:
  - `20251110000000_create_exams.rb`
  - `20251110000001_create_exam_rosters.rb`
- Backend:
  - Create `Exam` model with concerns: `Registration::Registerable`, `Roster::Rosterable`, `Assessment::Assessable`, `Assessment::Pointable`, `Assessment::Gradable`
  - Implement `materialize_allocation!` (delegates to `replace_roster!`)
  - Implement `allocated_user_ids` (returns roster user IDs)
  - Extend `Registration::CampaignsController` to support exam campaigns (campaignable_type: "Exam")
- Controllers: `ExamsController` (CRUD, scheduling) - teacher-facing only
- UI:
  - Basic exam creation/editing form for teachers
  - Extend campaign creation UI to support exams (reuses existing campaign views)
  - Teachers can create campaigns with exams as registerable items
- Limitations: No student registration flows, no grading UI, no grade schemes (deferred to later PRs)
- Feature Flag: Same `assessment_grading_enabled` flag gates exam creation and campaign setup
- Refs: [Exam model](05a-exam-model.md#exam-activerecord-model)
- Acceptance: Exam model exists with all concerns; teachers can create/edit exams; teachers can create exam campaigns; backend methods implemented; no student-facing features yet; feature flag gates UI.
```

```admonish example "PR-8.2 — Exam registration (student-facing)"
- Scope: Enable students to view and register for exams via campaigns.
- Dependencies: Requires PR-8.1 (Exam model + campaign support)
- Backend:
  - Extend `Registration::UserRegistrationsController` to handle exam registrations
  - Policy evaluation for exam eligibility (uses existing PolicyEngine)
- UI:
  - Student-facing exam registration flows (reuses existing registration views)
  - Display available exam campaigns
  - Registration button/form for eligible students
  - Confirmation and status display
- Feature Flag: Same `assessment_grading_enabled` flag gates student exam registration
- Refs: [Exam registration flow](05a-exam-model.md#exam-registration-flow)
- Acceptance: Students can view available exam campaigns; eligible students can register; allocation works for exams; roster materialization works; both FCFS and preference modes supported; ineligible students see appropriate error messages.
```

```admonish example "PR-8.3 — Read-only grade view"
- Scope: Read-only table displaying students and their final grades, with distinct indicators for absent/exempt statuses.
- Dependencies: Requires PR-7.2 (assessment show page with tabs)
- ViewComponent: `GradeTableComponent` — main table shows gradeable participations (pending + reviewed) with name, tutorial, grade, `graded_at`. The `"—"` indicator marks "not yet graded" (status `pending`, grade nil). Absent, exempt, and not-submitted participations are excluded from the main table and displayed in a separate "Special Cases" card below with a per-row reason label.
- Rake: Extend `assessment_playground.rake` with `seed_grades` task that writes `grade`, `graded_at`, `grader_id` directly on participations. Seed ~5% of exam participations as `absent` and ~2% as `exempt` for realistic test data.
- Rationale: Provides the visual foundation for grade display; the same component is reused when interactive editing is added later (PR-8.7). Distinct absent/exempt indicators are needed for Step 9 (grading schemes) so that distribution stats exclude non-participants. Seeded data via rake tasks is sufficient for testing the read path and unblocking Steps 9–12.
- Refs: [Grade Entry UI](12-views.md#grade-entry-interface), [Absence Tracking](04-assessments-and-grading.md#absence-tracking--no-shows)
- Acceptance: Grade table renders on assessment show page; displays seeded grades correctly; absent/exempt/not-submitted shown in a separate "Special Cases" card; not-yet-graded shown as `"—"` in the main table; works for any Gradable (assignments, exams, talks); feature flag gates UI.
```

```admonish example "PR-8.4 — Read-only point grid"
- Scope: Read-only students × tasks matrix with per-task scores and row totals, with distinct indicators for absent/exempt statuses.
- Dependencies: Requires PR-7.2 (tasks exist on assessments)
- ViewComponent: `PointGridComponent` — main table shows scoring participations (pending + reviewed, with `submitted_at` present) with dynamic task columns and a total column. The `"—"` indicator marks "not yet graded" cells (points nil, status `pending`). Absent, exempt, and not-submitted participations are excluded from the main table and displayed in a separate "Special Cases" card below with a per-row reason label.
- Rake: Extend `assessment_playground.rake` with `seed_task_points` task that creates `Assessment::TaskPoint` records with random scores and updates `participation.points_total`. Only reviewed participations get task points. Absent/exempt and not-submitted participations get no task points. Future-deadline assessments are skipped.
- Rationale: Provides the visual foundation; the same component is reused when interactive editing is added later (PR-8.8). Distinct absent/exempt indicators ensure Step 9 (grading schemes) can display meaningful distribution stats that exclude non-participants. Seeded data unblocks the grade scheme pipeline.
- Refs: [Point Entry UI](12-views.md#point-entry-interface), [Absence Tracking](04-assessments-and-grading.md#absence-tracking--no-shows)
- Acceptance: Point grid renders with dynamic task columns; totals calculated correctly; absent/exempt/not-submitted shown in a separate "Special Cases" card; not-yet-graded shown as `"—"` in the main table; works for any Pointable (assignments, exams); feature flag gates UI.
```

```admonish example "PR-8.5 — Participation creation (submission + backfill)"
- Scope: All paths that create `Assessment::Participation` records: lazy creation on student submission, deadline backfill job, and team fanout.
- Controllers: Update `SubmissionsController` to conditionally create/update participation
- Logic — Lazy creation (on submission upload, when `assessment_grading_enabled?`):
  - Create `Assessment::Participation` if not exists
  - Set `status: :pending`, `submitted_at = Time.current`, `tutorial_id = student.tutorial`
  - For team submissions: Create/update participations for all team members
  - When flag disabled: Use existing submission flow (no participation records created)
- Logic — Deadline backfill job:
  - Sidekiq job triggered after assignment deadline passes
  - For each roster student without a participation: create one with `status: :pending`, `submitted_at: nil`
  - Idempotent (safe to re-run)
  - Configurable via `config/schedule.yml` or triggered manually by teacher
  - Grace period: The backfill fires at `deadline`, not `friendly_deadline`. Students submitting during the grace period get their `submitted_at` patched by the lazy-creation path. This is by design — no special handling needed.
- Migration: Add `note` text column to `assessment_participations` (status-agnostic free-text annotation, teacher-facing only).
- Shared concern: `Assessment::AbsenceHandling` extracted here for reuse by both PR-8.7 and PR-8.8:
  - `mark_absent(participation)` sets `status: :absent`, leaves points/grade `nil`
  - `mark_exempt(participation, note:)` sets `status: :exempt` with optional note
  - Validation: `absent` → `exempt` transition allowed
- Refs: [Submission workflow](04-assessments-and-grading.md#usage-scenarios), [Assignment Lifecycle](04-assessments-and-grading.md#assignment-participation-lifecycle-digital-submission), [Absence Tracking](04-assessments-and-grading.md#absence-tracking--no-shows)
- Acceptance: Feature flag controls submission behavior; new submissions create participations; team fanout works; backfill job seeds remaining roster students after deadline; `submitted_at` distinguishes submitters from backfilled; `AbsenceHandling` concern works standalone; old submissions continue working unchanged; no breaking changes to existing functionality.
```

```admonish example "PR-8.6 — Submission GUI simplification (roster-based tutorials)"
- Scope: Remove manual tutorial selection from the student submission flow. With rosters, a student's tutorial is determined by their roster entry, not by a per-submission dropdown.
- Dependencies: Requires PR-8.5 (participations exist, roster is the source of truth for tutorial assignment)
- Changes:
  - Remove tutorial dropdown from `submissions/_form.html.erb` — derive `tutorial_id` from the student's roster membership instead.
  - Remove "Move to tutorial" UI (`_select_tutorial.html.erb`, `select_tutorial` / `move` controller actions).
  - Update `SubmissionsController` create/update params to no longer require `tutorial_id`.
  - Adapt tutor-facing views (`tutorials/_submission_row`) to use roster-based filtering.
  - Clean up CoffeeScript response handlers referencing tutorial errors (`create.coffee`, `update.coffee`).
- Refs: [Submission workflow](04-assessments-and-grading.md#usage-scenarios)
- Acceptance: Students can submit without choosing a tutorial; tutorial is auto-derived from roster; tutors still see submissions grouped by their tutorial; existing submissions retain their tutorial association; feature flag gates new behavior.
```

```admonish tip
PR-8.6 is an independent UX cleanup and can also be implemented at the
end of Step 8 (or even later). It does not block any of the interactive
entry PRs (8.7, 8.8) since those rely on the rake playground task for
development data, not on the live submission flow.
```

```admonish example "PR-8.7 — Interactive grade entry (service + write UI)"
- Scope: Add write capability to the read-only grade table from PR-8.3.
- Dependencies: Requires PR-8.3 (read-only grade view with absent/exempt display). Uses `AbsenceHandling` concern from PR-8.5. During development, the rake playground task provides all necessary participation data.
- Service: `Assessment::GradeEntryService`
  - `set_grade(participation, grade, grader)` sets `participation.grade`
  - Reuses `mark_absent` / `mark_exempt` from `Assessment::AbsenceHandling` (PR-8.5)
  - Validation: grade format/range checks
  - Audit: tracks `graded_by_id`, `graded_at`
  - Works for: Talks, oral exams, manual grade entry, output target for grade schemes
- Controller: Create `Assessment::GradesController` with `update`, `mark_absent`, `mark_exempt` actions (RESTful controller scoped to Gradable assessments). Also add `Assessment::ParticipationsController#index` (read-only, deferred from PR-8.3).
- Tutor access: Tutors can enter grades for exams when the teacher enables it (per-assessment permission). For exams, teachers are the primary graders but can delegate to tutors. Authorization scoped to the tutor's assigned tutorial group.
- Refs: [GradeEntryService](04-assessments-and-grading.md#assessmentgradeentryservice-service), [Absence Tracking](04-assessments-and-grading.md#absence-tracking--no-shows), [Grade Entry UI](12-views.md#grade-entry-interface), [Tutor Grading View](12-views.md#assessments-lectures---tutor)
- UI: Inline editing on the existing `GradeTableComponent` — click a grade cell, input field, save; bulk "Mark as absent" action for no-shows; `note` field editable per participation
- Acceptance: Teachers can enter grades directly for any Gradable including talks; tutors can enter grades for exams when permitted by teacher; teachers can mark students as absent (bulk) or exempt; `note` field editable; validation works; audit tracking visible; feature flag gates UI.
```

```admonish tip
PR-8.7 (grade entry for Gradable assessments) and PR-8.8 (point entry
for Pointable assessments) are fully independent and can be developed
in parallel. Both share only the `AbsenceHandling` concern from PR-8.5.
Each PR creates its own controller (`GradesController` / `TaskPointsController`)
with no overlap.
```

```admonish example "PR-8.8 — Interactive point entry (service + write UI)"
- Scope: Add write capability to the read-only point grid from PR-8.4.
- Dependencies: Requires PR-8.4 (read-only point grid with absent/exempt display). Uses `AbsenceHandling` concern from PR-8.5. Independent of PR-8.7 (both can be developed in parallel). During development, the rake playground task provides all necessary participation and task point data.
- Service: `Assessment::PointEntryService`
  - Fanout pattern creates TaskPoints per student (or team)
  - Supports any Pointable (assignments, task-based exams)
  - Calculates `participation.points_total` from task points
  - For Pointable+Gradable (exams): can optionally trigger grade scheme calculation
  - Reuses `mark_absent` / `mark_exempt` from `Assessment::AbsenceHandling` (PR-8.5)
- Controller: Create `Assessment::TaskPointsController` with `index`, `update`, and `update_team` actions (single controller for all point entry on Pointable assessments). The `index` action supports a `?tutorial_id=` filter — teachers see all students or filter by tutorial, tutors are automatically scoped to their own tutorials by authorization. The `update_team` action saves points for a team via `Assessment::TeamGradingService`, which fans out to individual `Assessment::TaskPoint` records for each team member.
- Authorization: Teachers can access any tutorial's view; tutors can only access their own tutorials. Same controller, same actions — the authorization layer determines scope.
- UI: Inline editing on the existing `PointGridComponent` — click a cell, number input, save, total updates; bulk "Mark as absent" action reuses `AbsenceHandling` concern (PR-8.5). Tutorial-scoped view (same `index`, filtered): team-based table with per-task point inputs, progress indicator (graded / total), filter by graded/not graded, submission file links, auto-calculated totals.
  - The grading view must show all roster students (not only those with `submitted_at` present). Students who missed the deadline but submitted externally (e.g. by email) should still be gradable by the tutor — no model-level constraint prevents this.
- Refs: [PointEntryService](04-assessments-and-grading.md#assessmentpointentryservice-service), [Absence Tracking](04-assessments-and-grading.md#absence-tracking--no-shows), [Point Entry UI](12-views.md#point-entry-interface), [Tutor Grading View](12-views.md#assessments-lectures---tutor), [TaskPointsController](11-controllers.md#assessmenttaskpointscontroller)
- Acceptance: Teachers can enter points for tasks; tutors can enter points for their tutorial's students (primary workflow for assignments); team grading propagates to individual records; totals calculated; bulk absent marking works; tutorial-scoped view filtered by authorization; UI agnostic to assessable type; feature flag gates UI.
```

```admonish example "PR-8.9 — Student results interface"
- Scope: Student-facing views for assessment results.
- Dependencies: Requires PR-8.7 (grade entry for Gradable assessments) and PR-8.8 (point entry for Pointable assessments)
- Controllers: `Assessment::ParticipationsController` (index, show for students)
- UI:
  - **Results Overview:** Progress dashboard (points earned, graded count, certification status), assignment list with filters (All/Graded/Pending), collapsible older assignments section
  - **Results Detail:** Per-assessment view with task breakdown table (if Pointable), final grade (if Gradable), submitted files, tutor feedback, team info, overall progress sidebar
  - Results filtered by `results_published_at` (null = hidden from students)
  - Works for assignments, exams, and talks (unified interface)
- Authorization: Students see only their own participations; results hidden when `results_published_at` is nil
- Refs: [Student results views](12-views.md#assessments-lectures---student)
- Acceptance: Students can view results; task points visible (if Pointable); final grade visible (if Gradable); feedback displayed; unpublished assessments hidden; works for any assessable type; feature flag gates access.
```

```admonish example "PR-8.10 — Publish/unpublish results"
- Scope: Teacher-facing toggle for result visibility.
- Dependencies: Requires PR-8.9 (student results interface exists to verify visibility)
- Controllers: Extend `Assessment::AssessmentsController` with `publish_results` and `unpublish_results` actions
- UI: Toggle button on assessment show page; works for grades, points, or both
- Refs: [Publication workflow](04-assessments-and-grading.md#publication-workflow)
- Acceptance: Teachers can publish/unpublish results; students see results only when published; toggle works via Turbo Frame; works for any assessable type; feature flag gates UI; end-to-end testable against student view from PR-8.9.
```

```admonish abstract
Exams — Step 9: Grade Schemes (Exam-Specific Layer)
```

```admonish example "PR-9.1 — Grade scheme schema"
- Scope: Create `assessment_grade_schemes` table; `Assessment::GradeScheme` model with factory and spec.
- Design decision: bands are stored as JSONB in `config` (no separate thresholds table). Bands are always read/written as a unit, JSONB keeps versioning via `version_hash` atomic, and the schema stays flexible for future `kind` values.
- Migration: `20260220000000_create_grade_schemes.rb`
- Refs: [Assessment::GradeScheme](05b-grading-schemes.md#assessmentgradescheme-activerecord-model)
- Acceptance: Migration runs; `Assessment::GradeScheme` model has correct associations, validations, `applied?`, `compute_hash`, and `config_matches_kind`; factory covers absolute-points, percentage, and applied traits; spec covers all validations and uniqueness of active scheme per assessment.
```

```admonish example "PR-9.2 — Grade scheme applier (service)"
- Scope: `Assessment::GradeSchemeApplier` for converting exam points to grades.
- Implementation: Supports absolute points and percentage-based bands; idempotent application via version_hash; respects manual overrides
- Refs: [Assessment::GradeSchemeApplier](05b-grading-schemes.md#assessmentgradeschemeapplier-service-object)
- Acceptance: Service computes grades from points; handles both absolute and percentage schemes; version_hash prevents duplicate applications.
```

```admonish example "PR-9.3 — Grade scheme UI + distribution analysis"
- Scope: UI for grade scheme configuration and application (layers on top of PR-8.4 point grid).
- Controllers: `Assessment::GradeSchemesController` (configuration, preview, apply)
- UI:
  - Distribution analysis (histogram, statistics) based on entered points
  - Scheme configuration (two-point auto-generation + manual adjustment)
  - Grade preview showing how scheme maps to students
  - Apply action (runs Assessment::GradeSchemeApplier)
- Integration: Uses existing read-only point grid from PR-8.4; adds grade scheme layer
- Refs: [Exam grading workflow](12-views.md#exam-grading-workflow)
- Acceptance: Teachers can create and apply grade schemes; preview grade distribution; apply action creates final grades; publication uses existing PR-8.10 toggle; feature flag gates UI.
```

```admonish abstract
Student Performance — Step 10: System Foundations
```

```admonish note
Step 10 was promoted ahead of Activity Tracking (now Step 12) because
student performance and exam eligibility are MVP-critical: the system
cannot gate exam registration without certifications. Achievement
tracking is a nice-to-have enhancement that can follow later.
```

```admonish tip
Step 10 was consolidated from 7 PRs to 4. The original split had
several very small PRs (pure service objects, thin controllers, tiny
background jobs) that are better reviewed together:
- Old 10.2 (ComputationService) + 10.3 (Evaluator) + 10.7 (jobs) →
  new **PR-10.2** (all backend services + jobs, no UI)
- Old 10.4 (RecordsController) + 10.6 (EvaluatorController) →
  new **PR-10.3** (all read-only/proposal UI)
- Old 10.5 (CertificationsController) → new **PR-10.4** (unchanged,
  the main write-heavy decision UI deserves isolated review)
```

```admonish example "PR-10.1 — Performance schema (Record, Rule, Achievement stub, Certification)"
- Scope: Create `student_performance_records`, `student_performance_rules`,
  `student_performance_rule_achievements`, `student_performance_certifications`.
  Also create `achievements` table and `Achievement` model shell
  (migration + associations only, no CRUD or UI) so that
  `StudentPerformance::Rule.required_achievements` resolves.
- Migrations:
  - `20251120000000_create_achievements.rb`
  - `20251120000001_create_student_performance_records.rb`
  - `20251120000002_create_student_performance_rules.rb`
  - `20251120000003_create_student_performance_rule_achievements.rb`
  - `20251120000004_create_student_performance_certifications.rb`
- Rationale: The Achievement table is created here as a schema stub.
  Rules can reference achievements via the join table, but with no
  Achievement CRUD yet, `required_achievements` is simply empty.
  The computation service handles this gracefully (empty = all met).
  Full Achievement CRUD and UI are deferred to Step 12 (post-MVP).
- Refs: [Student Performance models](05-student-performance.md#solution-architecture)
- Acceptance: Migrations run; models have correct associations; unique constraints on certifications; Achievement model exists but has no controller or UI.
```

```admonish example "PR-10.2 — Services & jobs (ComputationService, Evaluator, background jobs)"
- Scope: All backend service objects and background jobs for the
  student performance pipeline — no controllers or UI.
- Services:
  - `StudentPerformance::ComputationService`: reads from
    `assessment_participations` and `assessment_task_points`; upserts
    `student_performance_records`. When no achievements are configured
    on a rule, treats achievement criteria as met.
  - `StudentPerformance::Evaluator`: reads Records and Rules; returns
    proposed status (passed/failed) per student. Generates bulk
    proposals for the teacher certification UI. Does NOT create
    Certifications.
- Jobs:
  - `PerformanceRecordUpdateJob`: recomputes Records after grade
    changes (thin wrapper around `ComputationService`).
  - `CertificationStaleCheckJob`: flags stale certifications when
    Records change.
- Refs: [ComputationService](05-student-performance.md#lectureperformancecomputationservice-service),
  [Evaluator](05-student-performance.md#lectureperformanceevaluator-teacher-facing-proposal-generator),
  [Background jobs](09-integrity-and-invariants.md#recommended-background-jobs)
- Acceptance: ComputationService computes points and achievements; upserts Records; handles missing data gracefully; works with points-only rules (no achievements). Evaluator generates proposals; does NOT create Certifications. Jobs run on schedule; recomputed Records are accurate; stale certifications flagged for teacher review.
```

```admonish example "PR-10.3 — Read-only UI (Records + Evaluator + Rules read-only)"
- Scope: All read-only and proposal-generating UI for student
  performance — everything teachers see *before* making certification
  decisions. Adds the Assessments overview subtab navigation
  (`AssessmentsOverviewComponent`) with three subtabs: Assessments,
  Performance, and Rules (read-only).
- Controllers:
  - `StudentPerformance::RecordsController`: index/show actions for
    factual performance data.
  - `StudentPerformance::EvaluatorController`: `bulk_proposals`,
    `preview_rule_change`, `single_proposal`.
  - `StudentPerformance::RulesController`: `show` action (read-only
    display of the active rule and its criteria).
- UI:
  - `AssessmentsOverviewComponent` with subtab navigation
    (Assessments | Performance | Rules), feature-flag gated.
  - Records table view with points, achievements, `computed_at`
    timestamp.
  - Evaluator proposal list (bulk proposals for all students).
  - Modal for rule change preview showing diff of affected students.
  - Rules subtab: read-only display of the active rule (thresholds,
    linked achievements). Info alert: "Rule editing available in a
    future update."
- Refs: [RecordsController](11-controllers.md#lectureperformancerecordscontroller),
  [EvaluatorController](11-controllers.md#lectureperformanceevaluatorcontroller),
  [RulesController](11-controllers.md#lectureperformancerulescontroller)
- Acceptance: Teachers can view Records; teachers can generate proposals; preview rule changes; Rules subtab shows current criteria read-only; does NOT create Certifications automatically; feature flag gates access.
```

```admonish example "PR-10.4 — Certifications controller + Rules edit (teacher workflow)"
- Scope: `StudentPerformance::CertificationsController` for teacher
  certification — the write-heavy decision-making UI. Also adds
  write-side Rules (edit/update) and the Certifications subtab to
  `AssessmentsOverviewComponent`.
- Controllers:
  - `StudentPerformance::CertificationsController`: index (dashboard),
    create (bulk), update (override), bulk_accept.
  - `StudentPerformance::RulesController`: `edit`, `update` actions
    (criteria editing with rule change preview).
- UI:
  - Certifications subtab added to `AssessmentsOverviewComponent`
    (Assessments | Performance | Rules | Certifications).
  - Certification dashboard with proposals; bulk accept/reject;
    manual override with notes.
  - Rules subtab upgraded from read-only to editable: inline form
    for thresholds, achievement checkboxes, preview + save.
- Refs: [CertificationsController](11-controllers.md#lectureperformancecertificationscontroller),
  [RulesController](11-controllers.md#lectureperformancerulescontroller)
- Acceptance: Teachers can review proposals; bulk accept; override with manual status; edit rules with preview; Certifications subtab visible; remediation workflow for stale certifications.
```

```admonish abstract
Exam Eligibility — Step 11: Student Performance Policy Integration
```

```admonish example "PR-11.1 — Student performance policy (add to engine)"
- Scope: Add `student_performance` policy kind to `Registration::PolicyEngine`.
- Implementation: `Registration::Policy#eval_student_performance` checks
  `StudentPerformance::Certification.find_by(...).status`.
- Phase awareness: Returns different errors for registration
  (missing/pending) vs finalization (failed).
- Refs: [Policy evaluation](02-registration.md#policy-evaluation-interface)
- Acceptance: Policy checks Certification table; phase-aware logic; tests use Certification doubles.
```

```admonish example "PR-11.2 — Pre-flight checks (campaign open/finalize)"
- Scope: Add certification completeness checks to campaign lifecycle.
- Controllers: Update `Registration::CampaignsController#open` to check
  for missing/pending certifications; block if incomplete.
- Update `Registration::AllocationController#finalize` to check for
  missing/pending; auto-reject failed certifications.
- Refs: [Pre-flight validation](05-student-performance.md#policy-integration)
- Acceptance: Campaigns cannot open without complete certifications; finalization blocked if pending; failed certifications auto-rejected.
```

```admonish example "PR-11.3 — Eligibility UI integration"
- Scope: Wire eligibility checks into exam registration UI.
- Controllers: Extend existing exam registration controllers to handle
  student_performance policy errors.
- UI: Eligibility status displays; blocked registration with clear
  messaging; links to performance overview.
- Refs: [Exam registration flow](05a-exam-model.md#student-experience)
- Acceptance: Students see eligibility status; policy blocks ineligible users; clear error messages; links to certification details; feature flag gates UI.
```

```admonish example "PR-11.4 — Certification remediation workflow"
- Scope: UI for teachers to resolve pending certifications during finalization.
- Controllers: Add remediation actions to
  `StudentPerformance::CertificationsController`.
- UI: Remediation modal during finalization showing pending students;
  quick-resolve actions; bulk accept/reject.
- Refs: [Remediation workflow](05-student-performance.md#policy-integration)
- Acceptance: Teachers can resolve pending certifications inline during finalization; finalization retries after resolution; auto-rejection of failed students.
```

```admonish abstract
Activity Tracking — Step 12: Achievement CRUD & UI (post-MVP)
```

```admonish note
Activity tracking is a post-MVP enhancement. The Achievement table
already exists from Step 10 as a schema stub. This step adds the full
CRUD, marking UI, service integration, and student views across four
PRs.

**Dependency graph:**
- PR 12.1 is the foundation (model + CRUD).
- PR 12.2 (marking UI) and PR 12.4 (student view) can be developed
  in parallel on top of 12.1.
- PR 12.3 (service integration) depends on 12.2.
- PR 12.4 is intended for a different programmer and can proceed as
  soon as 12.1 lands.
```

```admonish example "PR-12.1 — Achievement CRUD"
- Scope: Wire the Achievement model into the Assessment infrastructure and provide full CRUD.
- Model: Add `include Assessment::Assessable` to Achievement (but NOT Pointable or Gradable). Add `after_create` callback to create assessment infrastructure (`requires_points: false`, `requires_submission: false`) and seed participations from the lecture roster. Note: the assessment callback is gated by `:assessment_grading`, while the CRUD UI is gated by `:student_performance`. Achievements can exist as lightweight entities without assessment infrastructure if only the UI flag is enabled.
- Controllers: `AchievementsController` (index, new, show, create, update, destroy) nested under lecture. The `show` action renders an `AchievementDashboardComponent` (following the assignment dashboard pattern) whose settings tab serves as the edit form.
- Routes: Nested resource under lectures, feature-flag gated.
- Ability: Reuses `LectureAbility` — any user who can `:edit` the lecture can manage achievements.
- Views: Achievement list (index with clickable rows), new-achievement form (rendered into container via Turbo Stream), dashboard with settings tab (title, value_type selector, conditional threshold input, description), delete with confirmation.
- i18n: Keys for both locales (titles, labels, flash messages, value type names).
- Rationale: Achievements track attendance/involvement but don't contribute to grades. Rules that only use point thresholds work without any achievements. This PR establishes the data foundation that marking (12.2) and the student view (12.4) build on.
- Refs: [Achievement model](04-assessments-and-grading.md#achievement-model), [Activity tracking](04-assessments-and-grading.md#activity-tracking)
- Acceptance: Achievement CRUD works; creating an achievement auto-creates its Assessment and seeds Participations; value_type validated; threshold conditional on type; deletion blocked when referenced by rules; feature flag gates UI.
```

```admonish example "PR-12.2 — Achievement marking UI"
- Scope: Teacher/tutor interface for marking student achievement completion.
- UI: Per-achievement student list showing participations. Input depends on value_type: boolean → checkbox (Pass/Fail), numeric → number input, percentage → number input with % suffix.
- Controller: Extend achievement's assessment show view with a marking/grading tab, or add marking actions to `AchievementsController`.
- Bulk actions: "Mark all as Pass" for boolean achievements.
- Persistence: Updates `Assessment::Participation#grade_value` for each student.
- Refs: [Tutor grading](05-student-performance.md#achievement-model)
- Acceptance: Teachers can mark achievements per student; correct input type shown per value_type; bulk marking works for boolean; changes persist to participation records; feature flag gates UI.
```

```admonish example "PR-12.3 — Achievement service integration"
- Scope: Wire achievements into the StudentPerformance computation pipeline.
- Model: Add `Achievement#student_met_threshold?(user)` method that reads `Assessment::Participation#grade_value` and compares against threshold/type.
- Service: Update `StudentPerformance::Service` to include achievement evaluation when computing records. Populate `achievements_met_ids` on `StudentPerformance::Record`.
- Evaluator: Update `StudentPerformance::Evaluator` to incorporate achievements into certification proposals (rules with achievement requirements).
- Triggers: Recompute affected `StudentPerformance::Record` when a participation's `grade_value` changes.
- Refs: [Service computation](05-student-performance.md#studentperformanceservice), [Evaluator](05-student-performance.md#studentperformanceevaluator)
- Acceptance: Service correctly evaluates achievement thresholds; records include `achievements_met_ids`; evaluator proposals reflect achievement status; recomputation fires on marking changes.
```

```admonish example "PR-12.4 — Student achievement progress view"
- Scope: Read-only student-facing view of their achievements in a lecture. Narrow scope: just achievements, not the broader performance dashboard (Steps 13-14).
- UI: List of achievements for the lecture with status per student: met/not met, current value vs threshold for numeric/percentage types.
- Controller: Student-accessible action (read-only) showing the current user's achievement participations.
- Note: This PR is intended for a different programmer and can be developed in parallel with 12.2/12.3, as it only depends on 12.1 (model + participations exist). Empty/pending states are shown for not-yet-marked achievements.
- Refs: [Student dashboard](student_dashboard.md)
- Acceptance: Students see their achievement status per lecture; correct display per value_type; graceful handling of unmarked achievements; feature flag gates UI.
```

```admonish note
**Status of Steps 13-14:** Steps 13 and 14 (Dashboards) remain at
high-level outline stage. Detailed PR breakdowns will be added during
implementation planning.
```

```admonish abstract
Dashboards — Step 13: Partial Integration
```

```admonish example "PR-13.1 — Student dashboard (partial)"
- Scope: Student dashboard with widgets for registrations, grades, exams, deadlines.
- Controllers: `Dashboards::StudentController` with widget partials.
- Widgets: "My Registrations", "Recent Grades", "Upcoming Exams", "Deadlines".
- Refs: [Student dashboard mockup](12-views.md#student-dashboard)
- Acceptance: Students see dashboard; widgets show data from new tables including exam registrations; exam eligibility widget hidden (added in Step 14).
```

```admonish example "PR-13.2 — Teacher/editor dashboard (partial)"
- Scope: Teacher dashboard with widgets for campaigns, rosters, grading, exams.
- Controllers: `Dashboards::TeacherController` with widget partials.
- Widgets: "Open Campaigns", "Roster Management", "Grading Queue", "Exam Management".
- Refs: [Teacher dashboard mockup](12-views.md#teacher-dashboard)
- Acceptance: Teachers see dashboard; widgets show actionable items including exam grading; certification widget hidden (added in Step 14).
```

```admonish abstract
Dashboards — Step 14: Complete Integration
```

```admonish example "PR-14.1 — Student dashboard extension"
- Scope: Add student performance and exam registration widgets.
- Widgets: "Exam Eligibility Status", "Performance Overview".
- Refs: [Student dashboard complete](12-views.md#student-dashboard)
- Acceptance: Students see eligibility status; performance summary; links to certification details.
```

```admonish example "PR-14.2 — Teacher dashboard extension"
- Scope: Add certification and exam management widgets.
- Widgets: "Certification Pending List", "Eligibility Summary".
- Refs: [Teacher dashboard complete](12-views.md#teacher-dashboard)
- Acceptance: Teachers see pending certifications; summary of eligible students; links to remediation UI.
```