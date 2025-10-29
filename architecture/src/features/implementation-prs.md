# Implementation PR Roadmap

This chapter breaks down the Registration system into small, reviewable
pull requests. It complements the Implementation Plan (steps 2–4) with
concrete PR scopes, dependencies, and acceptance criteria for the
Registration workstream.

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
```

```admonish abstract
Registration — Step 2: Foundations (Schema)
```

```admonish example "PR-2.1 — Schema and core models"
- Scope: AR models `Registration::Campaign`, `Item`, `UserRegistration`,
	`Policy` and additive migrations.
- Migrations:
	- 20251028000000_create_registration_campaigns.rb
	- 20251028000001_create_registration_items.rb
	- 20251028000002_create_registration_user_registrations.rb
	- 20251028000003_create_registration_policies.rb
- Refs: Models — [Campaign](02-registration.md#registrationcampaign-activerecord-model),
	[Item](02-registration.md#registrationitem-activerecord-model),
	[UserRegistration](02-registration.md#registrationuserregistration-activerecord-model),
	[Policy](02-registration.md#registrationpolicy-activerecord-model)
- Acceptance: Enums/validations present; associations wired; basic factories added.
- Out of scope: Controllers, services, UI.
```

```admonish example "PR-2.2 — Policy engine and core kinds"
- Scope: `Registration::PolicyEngine`; kinds: `institutional_email`,
	`exam_eligibility`, `prerequisite_campaign`.
- Refs: Service — [PolicyEngine](02-registration.md#registrationpolicyengine-service-object);
	Admin mockup ref — [Exams & Eligibility](../mockups/campaigns_show_exam.html)
- Acceptance: Unit tests incl. doubles for `ExamEligibility::Record`; deterministic
	pass/fail traces.
- Out of scope: Policies UI.
```

```admonish abstract
Registration — Step 3: FCFS mode (Admin + Student)
```

```admonish example "PR-3.1 — Admin: Campaigns + Policies scaffold"
- Scope: `Registration::CampaignsController` index/show/new/create/
	edit/update/destroy; member actions open/close/reopen. Add
	`Registration::PoliciesController` CRUD and minimal Policies tab.
- Refs: Controllers — [Registration controllers](11-controllers.md#registration-controllers).
	Mockups — [Index (lecture)](../mockups/campaigns_index.html),
	[Index (current term)](../mockups/campaigns_index_current_term.html),
	[Show (exam FCFS)](../mockups/campaigns_show_exam.html),
	[Show (tutorials FCFS open)](../mockups/campaigns_show_tutorial_fcfs_open.html),
	[Show (interest draft)](../mockups/campaigns_show_interest_draft.html)
- Views: Minimal ERB with Turbo Frames shells (tabs placeholders).
- Acceptance: CRUD + status transitions covered by request specs; routes and ability stubs in place. Policies can be created and reordered.
- Out of scope: Per-kind typed forms.
```

```admonish example "PR-3.2 — Student: Registration index (tabs)"
- Scope: `Registration::UserRegistrationsController#index` with tabs,
	filters, counts, and links to Show.
- Refs: Controller — [Registration controllers](11-controllers.md#registration-controllers).
	Mockup — [Student index (tabs)](../mockups/student_registration_index_tabs.html)
- Acceptance: Filters navigate via Turbo Frames; links to Show work.
```

```admonish example "PR-3.3 — FCFS: Single-item campaigns (student)"
- Scope: Register/Withdraw flow for single-item FCFS campaigns where the
	campaign itself enrolls the user (e.g., course/seminar enrollment).
- Refs: Controller — [Registration controllers](11-controllers.md#registration-controllers).
	Mockup — [Show – FCFS (single-item)](../mockups/student_registration_fcfs.html)
- Acceptance: Seats enforced; persisted state; disabled states.
```

```admonish example "PR-3.4 — FCFS: Multi-item picker (student)"
- Scope: Pick-one item with capacities in multi-item FCFS campaigns;
	require explicit withdraw before switching; disable full rows.
- Refs: Controller — [Registration controllers](11-controllers.md#registration-controllers).
	Mockup — [Show – FCFS (multi-item picker)](../mockups/student_registration_fcfs_tutorials.html)
- Acceptance: Withdraw-first rule; capacity guards; persisted state.
```

```admonish example "PR-3.5 — FCFS: Policy-gated registration (student)"
- Scope: FCFS Show with policy-gated registration (e.g., institutional
	email). Gate via link-out to Account page; enable register only when
	policies pass. Applies to any campaign host; exams are a common case.
- Refs: Controller — [Registration controllers](11-controllers.md#registration-controllers).
	Mockups — [Policy gate example](../mockups/student_registration_fcfs_exam_action_required_email.html),
	[FCFS (exam) example](../mockups/student_registration_fcfs_exam.html)
- Acceptance: Register enabled only when requirements satisfied.
```

```admonish example "PR-3.6 — Dashboard: Open registrations widget (hidden)"
- Scope: Expose endpoints for open registrations/counts and add a hidden
	dashboard card behind a feature flag; wire minimal view and test.
- Refs: Controllers — [Registration controllers](11-controllers.md#registration-controllers).
- Acceptance: Widget renders when flag enabled; off by default.
```

```admonish abstract
Registration — Step 4: Preference-based mode
```

```admonish example "PR-4.1 — Student Show (preference-based)"
- Scope: Show + preferences frame edit/update; rank add/remove/reorder.
- Refs: Controller — [Registration controllers](11-controllers.md#registration-controllers).
	Mockups — [Show – preference-based](../mockups/student_registration.html),
	[Confirmation](../mockups/student_registration_confirmation.html).
	Model — [UserRegistration](02-registration.md#registrationuserregistration-activerecord-model)
- Acceptance: Happy-path save; eligibility error shown from engine.
- Out of scope: Allocation results.
```

```admonish example "PR-4.2 — Production solver integration + finalize"
- Scope: Integrate production solver (MCMF/CP-SAT) into
  `Registration::AllocationService` and background job; implement
  operator-visible progress (logs/streams) and wire real
  `allocate!`/`finalize!`/`allocate_and_finalize!` end-to-end.
- Refs: Services — [Allocation details](07-algorithm-details.md).
  Controllers — [Registration controllers](11-controllers.md#registration-controllers).
- Acceptance: Real solver runs on sample data; deterministic results for
  tests; finalize persists to domain rosters; guardrails/flags in place.
```

```admonish example "PR-4.3 — Allocation controller + results (teacher)"
- Scope: `Registration::AllocationController` show/create/retry/finalize/
  allocate_and_finalize; views and stream slots; results tab surfaces
  assigned/unassigned and close‑out normalization.
- Refs: Controllers — [Registration controllers](11-controllers.md#registration-controllers).
  Services — [Allocation details](07-algorithm-details.md).
- Acceptance: Actions exist; authorization enforced; background job
  runs the integrated solver; results render for campaigns.
- Out of scope: Roster maintenance (see Plan Step 5).
```

```admonish example "PR-4.4 — Post-allocation wiring (student/index)"
- Scope: “View result” links from index; student confirmation screens.
- Refs: Mockups — [Index (tabs)](../mockups/student_registration_index_tabs.html),
	[Confirmation](../mockups/student_registration_confirmation.html)
- Acceptance: Closed tables link to correct confirmation screens.
```

```admonish example "PR-4.5 — Dashboard: Results summary widget (hidden)"
- Scope: Add endpoints and a hidden dashboard card summarizing latest
	allocation results (assigned/unassigned). Feature-flagged; minimal
	view and test.
- Refs: Controllers — [Registration controllers](11-controllers.md#registration-controllers).
- Acceptance: Widget renders when flag enabled; off by default.
```

```admonish note
Beyond Plan Steps 2–4 (Registration)
- Roster maintenance (read-only, edit/move) and unassigned sourcing.
- Typed policy forms and full admin eligibility screens.
- Dashboards integration polish, notifications, and background scheduling.
- Reporting and integrity jobs.
- Quality & hardening: tests, flags cleanup, metrics/logging, permissions, i18n.
```

```admonish abstract
Rosters — Step 5: Maintenance (UI & Operations)
```

```admonish example "PR-5.1 — Schema: tutorial_memberships join table"
- Scope: Add `tutorial_memberships` join table for tutorial rosters
	with FK indexes and uniqueness on `(tutorial_id, user_id)`. Wire
	basic associations on `Tutorial` (read-only for now). Behind a
	feature flag.
- Migrations:
	- 20251029000000_create_tutorial_memberships.rb
- Refs: Rosters — [Tutorial (Enhanced)](03-rosters.md#tutorial-enhanced)
- Acceptance: Can create/delete memberships via console/specs; DB
	uniqueness enforced; no UI yet.
- Out of scope: Roster service, controllers, views.
```

```admonish example "PR-5.2 — Concern: Roster::Rosterable + Tutorial"
- Scope: Add `Roster::Rosterable` concern and include it in `Tutorial`.
	Implement `roster_user_ids` and `replace_roster!` using
	`tutorial_memberships`. Unit tests for idempotency
	(`replace_roster!` with same set is a no-op) and contract errors on
	missing overrides.
- Files:
	- app/models/concerns/roster/rosterable.rb
- Refs: Rosters — [Rosterable](03-rosters.md#rosterrosterable-concern)
- Acceptance: Green model specs; contract covered.
- Out of scope: Talk implementation (can arrive later) and UI.
```

```admonish example "PR-5.3 — Service: Roster::MaintenanceService"
- Scope: Implement `move_user!`, `add_user!`, `remove_user!` with
	capacity enforcement (`full?`), transactions, and a stubbed
	`touch_counts!` hook. Add request-free service specs (happy path +
	capacity failure). Wire feature flag guardrails.
- Files:
	- app/services/roster/maintenance_service.rb
- Refs: Rosters — [MaintenanceService](03-rosters.md#rostermaintenanceservice)
- Acceptance: Service specs for move/add/remove pass; capacity guard
	exercised; no controller yet.
- Out of scope: UI and denormalized counters job.
```

```admonish example "PR-5.4 — Controller scaffold + read-only views"
- Scope: Introduce `Roster::MaintenanceController` with `index` and
	`show` (read-only). `index` lists groups for a lecture with capacity
	meters; `show` displays participants for a single group. Routes and
	abilities in place. Minimal ERB with Turbo Frame shells.
- Refs: Controllers — [Roster controllers](11-controllers.md#roster-controllers),
	Views — [Rosters](12-views.md#rosters-teachereditor)
- Acceptance: Navigation works for teacher/editor; no edit actions yet;
	tutor role sees read-only own groups (ability stub acceptable).
- Out of scope: Edit operations and candidates panel.
```

```admonish example "PR-5.5 — Edit ops on Detail (remove/move)"
- Scope: Enable remove and move operations on the Detail view using the
	service. Turbo-stream updates for participants list and capacity
	meters. Enforce capacity in controller with proper error flash.
- Refs: Controllers — [Roster controllers](11-controllers.md#roster-controllers),
	Service — [MaintenanceService](03-rosters.md#rostermaintenanceservice)
- Acceptance: Remove and move work end-to-end with optimistic UI; tests
	cover controller happy path and capacity failure.
- Out of scope: Manual add and candidates panel.
```

```admonish example "PR-5.6 — Overview: Candidates panel + manual Add"
- Scope: Add right-side "Candidates from campaign" panel on Overview
	listing users unassigned in a selected completed campaign. Search and
	assign-to-group action. Add a separate "Add student" manual action
	(by email/id). Panel is present for tutorials/seminars; not shown for
	exams. No swap action (explicitly out-of-scope).
- Refs: Rosters — [Managing unassigned candidates](03-rosters.md#managing-unassigned-candidates),
	Views — [Rosters](12-views.md#rosters-teachereditor)
- Acceptance: Selecting a completed campaign surfaces unassigned users;
	Assign and Add place users into target group respecting capacity; UI
	hidden for exams.
- Out of scope: Background recount; audit trail persistence.
```

```admonish example "PR-5.7 — Counters + integrity job"
- Scope: Update denormalized `Registration::Item.assigned_count` inside
	the maintenance service's `touch_counts!`. Add `RecountAssignedJob`
	and a rake task to reconcile counts. Schedule a low-frequency cron
	entry. Unit tests for the job.
- Refs: Rosters — [Solution Architecture](03-rosters.md#solution-architecture)
- Acceptance: Service updates counters; job recomputes accurately on a
	seeded dataset; schedule present (disabled by default in dev).
```

```admonish example "PR-5.8 — Permissions + tutor read-only variant"
- Scope: Finalize abilities so tutors see read-only Detail for their
	groups; hide edit controls and candidates panel. Ensure exams do not
	render candidates panel. Add request specs covering access rules.
- Refs: Views — [Tutor (read-only) mockup](../mockups/roster_detail_tutor.html),
	Controllers — [Roster controllers](11-controllers.md#roster-controllers)
- Acceptance: Access rules enforced; UI elements conditionally hidden;
	tests green.
```

```admonish example "PR-5.9 — Dashboard: Manage Rosters widget (hidden)"
- Scope: Add a hidden teacher/editor dashboard card exposing quick
	links to Roster Overview plus simple counts (groups, participants,
	capacity utilization). Feature-flagged.
- Refs: Dashboards — [Teacher & Editor Dashboard](teacher_editor_dashboard.md)
- Acceptance: Card renders when flag enabled; off by default.
```