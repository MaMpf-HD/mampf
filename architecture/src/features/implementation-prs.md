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

```admonish example "PR-5.8 — Integrity job (assigned/allocated reconciliation)"
- Scope: Background job to verify roster consistency.
- Job: `AllocatedAssignedMatchJob` compares `Item#assigned_users` with `Registerable#allocated_user_ids`.
- Monitoring: Logs mismatches for admin review.
- Refs: [Integrity invariants](09-integrity-and-invariants.md#registration-allocation)
- Acceptance: Job runs nightly; reports mismatches; no auto-fix (manual review required).
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
Grading — Step 7: Assessments (Formalize Assignments)
```

```admonish example "PR-7.1 — Assessment backend (Assignment integration)"
- Scope: Integrate Assessment::Assessable into Assignment model with automatic participation seeding.
- Backend:
  - Add `Assessment::Assessable` concern
  - Include concern in Assignment model (behind feature flag)
  - Add `after_create :setup_assessment` hook
  - Implement `seed_participations_from_roster!` for Assignment
- Feature Flag: `assessment_grading_enabled` (per-lecture)
- Behavior: When enabled, new assignments automatically create Assessment record + Participations for all lecture students
- Refs: [Assessment::Assessable](04-assessments-and-grading.md#assessmentassessable-concern)
- Acceptance: Feature flag works; new assignments get assessments; participations seeded from roster; old assignments unaffected.
```

```admonish example "PR-7.2 — Assessment UI (CRUD without grading)"
- Scope: Complete assessment management UI (create, view, configure) without grading interface.
- Controllers: `Assessment::AssessmentsController` (full CRUD), `Assessment::TasksController` (nested CRUD), `Assessment::ParticipationsController` (index only)
- UI:
  - "New Assessment" form (type/mode selection, schedule)
  - Index page (list, filter, status badges)
  - Show page with tabs (Overview, Settings, Tasks, Participants)
  - Task management (add/edit/reorder problems)
  - Participation list (auto-seeded from PR-7.1)
- Limitations: No point entry, no grade calculation, no result publication (deferred to PR-8.x)
- Feature Flag: Same `assessment_grading_enabled` flag gates entire UI
- Refs: [Assessment controllers](11-controllers.md#assessmentassessmentscontroller), [Views](12-views.md#assessments)
- Acceptance: Teachers can create assessments via UI; participations visible; tasks configurable; no grading actions available; feature flag gates access.
```

```admonish example "PR-7.3 — Submission assessment support (dual-column)"
- Scope: Add `assessment_id` to submissions table; maintain backward compatibility with `assignment_id`.
- Migration:
  - Add `assessment_id` column (UUID, nullable) to `submissions` table
  - Add foreign key constraint on `assessment_id`
  - Keep existing `assignment_id` column and constraint (legacy support)
- Model Changes:
  - `belongs_to :assignment, optional: true` (legacy)
  - `belongs_to :assessment, optional: true` (new)
  - Validation: require one or the other (XOR pattern)
  - Helper method: `grading_context` returns assessment or assignment
- Controller Changes:
  - For new submissions (when feature flag enabled): set `assessment_id`
  - For old submissions: continue using `assignment_id`
  - Views use `submission.grading_context` for navigation
- Strategy: New submissions under feature flag use assessment_id; old submissions remain unchanged; both work simultaneously
- Refs: [Submission dual-column pattern](04-assessments-and-grading.md#submission-extended-model)
- Acceptance: Old submissions still work; new submissions link to assessments; no data loss; both columns coexist; feature flag determines which column is populated for new records.
```

```admonish abstract
Grading — Step 8: Assignment Grading
```

```admonish example "PR-8.0 — Student submission integration with participations"
- Scope: Update student submission workflow to interact with Assessment::Participation (when feature flag enabled).
- Controllers: Update `SubmissionsController` to conditionally set participation status.
- Logic (when `assessment_grading_enabled?`):
  - On submission upload: Find or create `Assessment::Participation` for student(s)
  - Set `participation.status = :submitted`, `submitted_at = Time.current`
  - Set `submission.assessment_id` (new column from PR-7.3)
  - For team submissions: Update all team members' participations
- Logic (when flag disabled):
  - Use existing submission flow with `assignment_id`
  - No participation records created
- Refs: [Submission workflow](04-assessments-and-grading.md#usage-scenarios)
- Acceptance: Feature flag controls behavior; new submissions link to assessments and update participations; old submissions continue working unchanged; no breaking changes to existing functionality.
```

```admonish example "PR-8.1 — Grading service (backend)"
- Scope: `Assessment::GradingService` for saving points and grades.
- Implementation: Fanout pattern creates Participation and TaskPoints
  per student (or team).
- Refs: [GradingService](04-assessments-and-grading.md#assessmentgradingservice-service)
- Acceptance: Service creates participations and task points; handles team grading; validates point ranges.
```

```admonish example "PR-8.2 — Grading UI (teacher/TA)"
- Scope: Grading interface for entering points.
- Controllers: `Assessment::GradingController` (new/create/update).
- UI: Grid view with students × tasks; inline editing; Turbo Frames for updates.
- Refs: [Grading UI mockup](12-views.md#grading-interface)
- Acceptance: Teachers can enter points; service called on save; results preview shown; feature flag gates UI.
```

```admonish example "PR-8.3 — Publish/unpublish results"
- Scope: Toggle result visibility for students.
- Controllers: Extend `Assessment::AssessmentsController` with
  `publish_results` and `unpublish_results` actions.
- UI: Toggle button on assessment show page.
- Refs: [Publication workflow](04-assessments-and-grading.md#publication-workflow)
- Acceptance: Teachers can publish/unpublish results; students see results only when published; toggle works via Turbo Frame; feature flag gates UI.
```

```admonish example "PR-8.4 — Student results interface"
- Scope: Student-facing views for published assessment results.
- Controllers: `Assessment::ParticipationsController` (index, show for students)
- UI:
  - **Results Overview:** Progress dashboard (points earned, graded count, certification status), assignment list with filters (All/Graded/Pending), collapsible older assignments section
  - **Results Detail:** Per-assignment view with task breakdown table, submitted files, tutor feedback, team info, overall progress sidebar
  - Published results only (students cannot see unpublished grades)
- Authorization: Students see only their own participations; results hidden when `assessment.results_published == false`
- Navigation: Links from assignment pages to results; download feedback PDFs
- Refs: [Student results views](12-views.md#assessments-lectures---student)
- Acceptance: Students can view published results; task points visible; feedback displayed; unpublished assessments hidden; certification status shown; feature flag gates access.
```
- Refs: [Publication workflow](04-assessments-and-grading.md#publication-workflow)
- Acceptance: Teachers can publish/unpublish results; students see results only when published.
```

```admonish abstract
Exams — Step 9: Registration & Grading
```

```admonish example "PR-9.1 — Exam schema and model"
- Scope: Create `exams` table and `Exam` model with concerns.
- Migrations:
  - `20251110000000_create_exams.rb`
- Concerns: `Registration::Registerable`, `Roster::Rosterable`,
  `Assessment::Assessable`.
- Implementation: `materialize_allocation!` delegates to `replace_roster!`;
  `allocated_user_ids` returns roster user IDs.
- Refs: [Exam model](05a-exam-model.md#exam-activerecord-model)
- Acceptance: Exam model exists with all concerns; belongs_to lecture; methods implemented; no functional changes to existing data.
```

```admonish example "PR-9.2 — Grade scheme schema"
- Scope: Create `grade_schemes` and `grade_scheme_thresholds`.
- Migrations:
  - `20251110000001_create_grade_schemes.rb`
  - `20251110000002_create_grade_scheme_thresholds.rb`
- Refs: [GradeScheme models](05b-grading-schemes.md#grading-scheme-models)
- Acceptance: Migrations run; models have correct validations; percentage-based thresholds supported.
```

```admonish example "PR-9.3 — Exam registration (campaign integration)"
- Scope: Enable exam registration using existing campaign infrastructure.
- Controllers: Extend `Registration::CampaignsController` to support
  lecture-hosted exam campaigns; extend
  `Registration::UserRegistrationsController` for exam context.
- UI: Exam registration flows; reuses campaign show/index views with
  exam-specific context.
- Refs: [Exam registration flow](05a-exam-model.md#exam-registration-flow)
- Acceptance: Teachers can create exam campaigns (lecture as campaignable, exam as registerable item); students can register for exams; FCFS and preference-based modes work; feature flag gates UI.
```

```admonish example "PR-9.4 — Grade scheme applier (service)"
- Scope: `GradeScheme::Applier` for converting exam points to grades.
- Implementation: Supports absolute points and percentage-based bands;
  idempotent application via version_hash; respects manual overrides.
- Refs: [GradeScheme applier](05b-grading-schemes.md#gradeschemesapplier-service-object)
- Acceptance: Service computes grades from points; handles both absolute and percentage schemes; version_hash prevents duplicate applications.
```

```admonish example "PR-9.5 — Exam grading UI"
- Scope: Complete exam grading workflow from point entry to grade publication.
- Controllers: `ExamsController` (CRUD, scheduling),
  `GradeScheme::SchemesController` (scheme configuration, preview, apply).
- UI: Point entry grid; distribution analysis (histogram, statistics);
  scheme configuration (two-point auto-generation + manual adjustment);
  grade preview and application; results publication.
- Refs: [Exam grading workflow](12-views.md#exam-grading-workflow)
- Acceptance: Teachers can enter exam points; create and apply grade schemes; preview grade distribution; publish results to students; feature flag gates UI.
```

```admonish abstract
Grading — Step 10: Participation Tracking
```

```admonish example "PR-10.1 — Achievement model (new assessable type)"
- Scope: Create Achievement as assessable for non-graded participation.
- Model: `Achievement` with `value_type` (boolean/numeric/percentage).
- Refs: [Achievement model](04-assessments-and-grading.md#achievement-model)
- Acceptance: Achievement model exists; can be linked to assessments; value_type validated.
```

```admonish example "PR-10.2 — Achievement marking UI"
- Scope: UI for teachers to mark achievements.
- Controllers: Extend `Assessment::ParticipationsController` with
  achievement marking actions.
- UI: Checkbox/numeric input for marking; student list view.
- Refs: [Participation tracking](04-assessments-and-grading.md#participation-tracking)
- Acceptance: Teachers can mark achievements; students see progress; feature flag gates UI.
```

```admonish abstract
Dashboards — Step 11: Partial Integration
```

```admonish example "PR-11.1 — Student dashboard (partial)"
- Scope: Student dashboard with widgets for registrations, grades, exams, deadlines.
- Controllers: `Dashboards::StudentController` with widget partials.
- Widgets: "My Registrations", "Recent Grades", "Upcoming Exams", "Deadlines".
- Refs: [Student dashboard mockup](12-views.md#student-dashboard)
- Acceptance: Students see dashboard; widgets show data from new tables including exam registrations; exam eligibility widget hidden (added in Step 14).
```

```admonish example "PR-11.2 — Teacher/editor dashboard (partial)"
- Scope: Teacher dashboard with widgets for campaigns, rosters, grading, exams.
- Controllers: `Dashboards::TeacherController` with widget partials.
- Widgets: "Open Campaigns", "Roster Management", "Grading Queue", "Exam Management".
- Refs: [Teacher dashboard mockup](12-views.md#teacher-dashboard)
- Acceptance: Teachers see dashboard; widgets show actionable items including exam grading; certification widget hidden (added in Step 14).
```

```admonish abstract
Student Performance — Step 12: System Foundations
```

```admonish example "PR-12.1 — Performance schema (Record, Rule, Achievement, Certification)"
- Scope: Create `student_performance_records`, `student_performance_rules`,
  `student_performance_achievements`, `student_performance_certifications`.
- Migrations:
  - `20251120000000_create_student_performance_records.rb`
  - `20251120000001_create_student_performance_rules.rb`
  - `20251120000002_create_student_performance_achievements.rb`
  - `20251120000003_create_student_performance_certifications.rb`
- Refs: [Student Performance models](05-student-performance.md#solution-architecture)
- Acceptance: Migrations run; models have correct associations; unique constraints on certifications.
```

```admonish example "PR-12.2 — Computation service (materialize Records)"
- Scope: `StudentPerformance::ComputationService` to aggregate performance data.
- Implementation: Reads from `assessment_participations` and
  `assessment_task_points`; writes to `student_performance_records`.
- Refs: [ComputationService](05-student-performance.md#lectureperformancecomputationservice-service)
- Acceptance: Service computes points and achievements; upserts Records; handles missing data gracefully.
```

```admonish example "PR-12.3 — Evaluator (proposal generator)"
- Scope: `StudentPerformance::Evaluator` to generate certification proposals.
- Implementation: Reads Records and Rules; returns proposed status
  (passed/failed) per student.
- Refs: [Evaluator](05-student-performance.md#lectureperformanceevaluator-teacher-facing-proposal-generator)
- Acceptance: Evaluator generates proposals; does NOT create Certifications; used for bulk UI only.
```

```admonish example "PR-12.4 — Records controller (factual data display)"
- Scope: `StudentPerformance::RecordsController` for viewing performance data.
- Controllers: Index/show actions for Records.
- UI: Table view with points, achievements, computed_at timestamp.
- Refs: [RecordsController](11-controllers.md#lectureperformancerecordscontroller)
- Acceptance: Teachers can view Records; no decision-making UI; feature flag gates access.
```

```admonish example "PR-12.5 — Certifications controller (teacher workflow)"
- Scope: `StudentPerformance::CertificationsController` for teacher certification.
- Controllers: Index (dashboard), create (bulk), update (override),
  bulk_accept.
- UI: Certification dashboard with proposals; bulk accept/reject; manual override with notes.
- Refs: [CertificationsController](11-controllers.md#lectureperformancecertificationscontroller)
- Acceptance: Teachers can review proposals; bulk accept; override with manual status; remediation workflow for stale certifications.
```

```admonish example "PR-12.6 — Evaluator controller (proposal endpoints)"
- Scope: `StudentPerformance::EvaluatorController` for proposal generation.
- Controllers: `bulk_proposals`, `preview_rule_change`, `single_proposal`.
- UI: Modal for rule change preview showing diff of affected students.
- Refs: [EvaluatorController](11-controllers.md#lectureperformanceevaluatorcontroller)
- Acceptance: Teachers can generate proposals; preview rule changes; does NOT create Certifications automatically.
```

```admonish abstract
Exam Eligibility — Step 13: Student Performance Policy Integration
```

```admonish example "PR-13.1 — Student performance policy (add to engine)"
- Scope: Add `student_performance` policy kind to `Registration::PolicyEngine`.
- Implementation: `Registration::Policy#eval_student_performance` checks
  `StudentPerformance::Certification.find_by(...).status`.
- Phase awareness: Returns different errors for registration
  (missing/pending) vs finalization (failed).
- Refs: [Policy evaluation](02-registration.md#policy-evaluation-interface)
- Acceptance: Policy checks Certification table; phase-aware logic; tests use Certification doubles.
```

```admonish example "PR-13.2 — Pre-flight checks (campaign open/finalize)"
- Scope: Add certification completeness checks to campaign lifecycle.
- Controllers: Update `Registration::CampaignsController#open` to check
  for missing/pending certifications; block if incomplete.
- Update `Registration::AllocationController#finalize` to check for
  missing/pending; auto-reject failed certifications.
- Refs: [Pre-flight validation](05-student-performance.md#policy-integration)
- Acceptance: Campaigns cannot open without complete certifications; finalization blocked if pending; failed certifications auto-rejected.
```

```admonish example "PR-13.3 — Eligibility UI integration"
- Scope: Wire eligibility checks into exam registration UI.
- Controllers: Extend existing exam registration controllers to handle
  student_performance policy errors.
- UI: Eligibility status displays; blocked registration with clear
  messaging; links to performance overview.
- Refs: [Exam registration flow](05a-exam-model.md#student-experience)
- Acceptance: Students see eligibility status; policy blocks ineligible users; clear error messages; links to certification details; feature flag gates UI.
```

```admonish example "PR-13.4 — Certification remediation workflow"
- Scope: UI for teachers to resolve pending certifications during finalization.
- Controllers: Add remediation actions to
  `StudentPerformance::CertificationsController`.
- UI: Remediation modal during finalization showing pending students;
  quick-resolve actions; bulk accept/reject.
- Refs: [Remediation workflow](05-student-performance.md#policy-integration)
- Acceptance: Teachers can resolve pending certifications inline during finalization; finalization retries after resolution; auto-rejection of failed students.
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

```admonish abstract
Quality — Step 15: Hardening & Integrity
```

```admonish example "PR-15.1 — Background jobs (performance/certification)"
- Scope: Create integrity jobs for student performance.
- Jobs: `PerformanceRecordUpdateJob` (recompute Records after grading),
  `CertificationStaleCheckJob` (flag stale certifications),
  `AllocatedAssignedMatchJob` (verify roster consistency).
- Refs: [Background jobs](09-integrity-and-invariants.md#background-jobs)
- Acceptance: Jobs run on schedule; log issues; no auto-fix for critical data.
```

```admonish example "PR-15.2 — Admin reporting (integrity dashboard)"
- Scope: Admin UI for monitoring data integrity.
- Controllers: `Admin::IntegrityController` with dashboard views.
- Widgets: Pending certifications, stale certifications, roster mismatches.
- Refs: [Monitoring](09-integrity-and-invariants.md#monitoring-alerts)
- Acceptance: Admins see integrity metrics; drill-down to affected records; export reports.
```