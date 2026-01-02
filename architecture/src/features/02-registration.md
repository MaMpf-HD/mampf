# Registration System

```admonish question "What is a 'Registration System'?"
A registration system manages time-bounded processes where users sign up for course-related activities with constraints and preferences.

- **Common Examples:** "Tutorial signup for Linear Algebra", "Seminar talk selection", "Exam registration with eligibility checks"
- **In this context:** A flexible campaign-based system supporting direct assignment, preference-based allocation, and composable eligibility policies with automated domain materialization.
```

## Problem Overview
MaMpf needs a flexible registration system to handle:
- **Regular courses:** Students register for tutorials within a lecture
- **Seminars:** Students register for talks within a seminar (special type of lecture)
- **Mixed scenarios:** Combining lecture enrollment with tutorial/talk assignment via a chained process

## Solution Architecture
We use a unified system with:
- **Registration Campaigns:** Time-bounded processes for registration
- **Polymorphic Design:** Any model can become registerable or campaignable (host campaigns)
- **Two-step Chaining:** Optional prerequisite campaigns (e.g., must register for seminar before selecting talks) implemented via a `prerequisite_campaign` policy
- **Allocation Persistence:** Store the final allocation (confirmed vs rejected) and optional per-item counters
- **Strategy Layer:** Pluggable solver for preference-based allocation (Min-Cost Flow now; CP-SAT later)
- **Domain Materialization (mandatory):** After allocation, propagate confirmed assignments back into domain models (e.g., populate talk speakers, tutorial rosters)
- **Registration Policies:** Composable eligibility rules (student performance, institutional email, prerequisite, etc.)
- **Policy Phases:** Policies declare a phase: `registration`, `finalization`, or `both`. Only policies applicable to the current phase are evaluated/enforced. See Student Performance → Certification (`05-student-performance.md`) for how finalization uses Certification.
- **Policy Engine:** Phase-aware evaluation of ordered active policies; short-circuits on first failure

---

```admonish tip "Glossary (Registration)"
- **Allocation mode:** Enum selecting `first_come_first_served` or `preference_based`.
- **AllocationService:** Computes allocations (preference-based) via `allocate!`.
- **AllocationMaterializer:** Applies confirmed allocations to domain rosters.
- **Campaign methods:** `allocate!`, `finalize!`, `allocate_and_finalize!`.
- **Policy phases:** `registration` gates intake; `finalization` gates roster materialization; `both` applies in both places.
- **Assigned users:** Users with `confirmed` status in the registration system (`Registration::UserRegistration.confirmed`). This is registration-side data.
- **Allocated users:** Users materialized into the domain roster after finalization (`Tutorial#students`, `Talk#speakers`, etc.). This is domain-side data. After finalization, assigned and allocated should match.
```

```admonish tip "Related UI mockups"
- Campaigns index (lecture): [Campaigns index](../mockups/campaigns_index.html)
- Campaigns index (current term): [Campaigns index (current term)](../mockups/campaigns_index_current_term.html)
- Exam Registration (Show): [Exam Show](../mockups/campaigns_show_exam.html)
- Tutorial Registration (preference-based, open): [Tutorial Show (open)](../mockups/campaigns_show_tutorial_open.html)
- Tutorial Registration (preference-based, completed): [Tutorial Show (completed)](../mockups/campaigns_show_tutorial.html)
- Tutorial Registration (FCFS, open): [Tutorial FCFS Show (open)](../mockups/campaigns_show_tutorial_fcfs_open.html)
- Interest Registration (planning-only, draft): [Interest Show (draft)](../mockups/campaigns_show_interest_draft.html)
- Student Registration (Index – tabs): [Student index](../mockups/student_registration_index_tabs.html)
```

### Usage Scenarios
- A **`Tutorial`** includes `Registerable` to manage its student roster.
- A **`Talk`** includes `Registerable` to designate students as its speakers.
- A **`Lecture`** (acting as a course) includes `Registerable` to manage direct enrollment.
- A **`Cohort`** includes `Registerable` to manage subgroups like "Repeaters".
- A future **`Exam`** model would include `Registerable` to manage allocation for an exam.

## Configuration Patterns

To ensure consistent rosters, the system encourages specific campaign combinations via the "New Campaign" wizard.

### Pattern 1: The "Group Track" (Standard)
Use this when your lecture has sub-groups (Tutorials or Talks).
- **Primary Campaign:** "Group Registration" (Items: All Tutorials/Talks).
- **Secondary Campaign (Optional):** "Special Groups" (Item: Cohort "Repeaters").
- **Roster Logic:** The Lecture Roster is the **union** of all Group members and Cohort members.

### Pattern 2: The "Enrollment Track" (Simple)
Use this when your lecture has no subgroups (e.g., Advanced Lecture, Ringvorlesung).
- **Primary Campaign:** "Course Enrollment" (Item: The Lecture itself).
- **Roster Logic:** The Lecture Roster is the list of registered students.

### Pattern 3: The "Mixed Track" (Discouraged)
It is possible to have both a "Group Registration" and a "Course Enrollment" campaign active simultaneously.
- **Use Case:** When lecture enrollment is technically required (e.g. for Moodle access) but groups are optional.
- **Implication:** This creates two parallel rosters. A student might be in a group but fail to register for the lecture.
- **System Behavior:** The wizard requires explicit acknowledgement to enable this track.

## Registration::Campaign (ActiveRecord Model)
**_The Registration Process Orchestrator_**

```admonish info "What it represents"
A time-bounded administrative process where users can register for specific items under a chosen mode.
```

```admonish tip "Think of it as"
“Tutorial Registration Week”, “Seminar Talk Selection Period”, “Exam Signup”
```

The main fields and methods of `Registration::Campaign` are:

| Name/Field                | Type/Kind         | Description                                                                                  |
|---------------------------|-------------------|----------------------------------------------------------------------------------------------|
| `campaignable_type`       | DB column         | Polymorphic type for the campaign host (e.g., Lecture)                                     |
| `campaignable_id`         | DB column         | Polymorphic ID for the campaign host                                                         |
| `title`                   | DB column         | Human-readable campaign title                                                                 |
| `allocation_mode`         | DB column (Enum)  | Registration mode: `first_come_first_served` or `preference_based`                            |
| `status`                  | DB column (Enum)  | Campaign state: `draft`, `open`, `closed`, `processing`, `completed`                        |
| `planning_only`           | DB column (Bool)  | Planning/reporting only; prevents materialization/finalization (default: false)              |
| `registration_deadline`   | DB column         | Deadline for user registrations (registration requests)                                      |
| `registration_items`      | Association       | Items available for registration within this campaign                                        |
| `user_registrations`      | Association       | User registrations (registration requests) for this campaign                                 |
| `registration_policies`   | Association       | Eligibility and other policies attached to this campaign                                     |
| `evaluate_policies_for(user, phase: :registration)` | Method      | Returns a structured eligibility result for the given phase (delegates to Policy Engine)                         |
| `policies_satisfied?(user, phase: :registration)` | Method      | Boolean convenience that returns true when all applicable policies pass                                 |
| `open_for_registrations?` | Method            | Returns true if campaign is currently accepting registrations                                 |
| `allocate!`               | Method            | Computes allocation (preference-based) without materialization                               |
| `finalize!`               | Method            | Enforces finalization-phase policies, then materializes the latest allocation into domain rosters                                       |
| `allocate_and_finalize!`  | Method            | Convenience: computes allocation and then finalizes                                          |

```admonish note
Eligibility is not a single field or method, but is determined dynamically by evaluating all active `registration_policies` for the campaign using the `evaluate_policies_for(user, phase:)` method, which delegates to the phase-aware policy engine. Use `policies_satisfied?(user, phase:)` as a boolean convenience.
```

```admonish tip "API at a glance"
- `evaluate_policies_for(user, phase: :registration)` → Result (fields: `pass`, `failed_policy`, `trace`, `details`)
- `policies_satisfied?(user, phase: :registration)` → Boolean (`true` when all applicable policies pass)
- `open_for_registrations?` → Boolean (campaign currently accepts registrations)

 See also: Controller endpoints in [Controller Architecture → Registration Controllers](11-controllers.md#registration-controllers).
```

### Behavior Highlights

- Guards registration window (`open?`)
- Delegates fine-grained eligibility to ordered `RegistrationPolicies` via Policy Engine
- Triggers solver (preference-based) after close (often at/after deadline)
- Finalizes and materializes allocation once only (idempotent)

#### Assigned vs Unassigned

- Assigned: the student has exactly one `confirmed` `Registration::UserRegistration` in the campaign after allocation/close.
- Unassigned: the student participated (has registrations) but has zero `confirmed` entries. On close/finalization, any remaining `pending` entries are normalized to `rejected` so the state is explicit.
- No extra tables are required. Helper methods on `Registration::Campaign` can expose `unassigned_user_ids`, `unassigned_users`, and `unassigned_count` computed from `UserRegistration` records.

```admonish note "Status semantics"
Statuses are mode-specific:
- First-come-first-served (FCFS): registrations are immediately `confirmed` or `rejected`.
- Preference-based: registrations are `pending` until allocation, then resolved to `confirmed` or `rejected` on finalize.

Do not overload `pending` to represent eligibility uncertainty in FCFS; use policy `details` (e.g., `stability`) purely for UI messaging.
```

#### Close vs Finalize

- **Close registration:** stops intake and edits; transitions `open → closed`.
  Used to lock the window early or when the deadline passes automatically.
- **Run allocation (preference-based only):** triggers solver; transitions `closed → processing`.
  FCFS campaigns skip this step (results already determined).
- **Finalize results:** before materialization, evaluates all active policies whose phase is `finalization` or `both` for each confirmed user (via a `Registration::FinalizationGuard`). A `student_performance` policy in finalization phase requires `Certification=passed` for all confirmed users. If any user fails a finalization-phase policy (or has missing/pending certification) the process aborts and status remains `processing` (or `closed` for FCFS) for remediation. After passing guards, materializes confirmed results and transitions to `completed`.
- **Planning-only campaigns:** close only; do not call `finalize!`. Results remain in reporting tables and are not materialized. When `planning_only` is true, `finalize!`/`allocate_and_finalize!` are no-ops.
- **Lecture performance completeness checks:**
  - **Campaign save:** Warns if any students lack certifications (any phase with student_performance policy)
  - **Campaign open:** Hard-fails if any students have missing/pending certifications (registration or both phase)
  - **Campaign finalize:** Hard-fails if any confirmed registrants have missing/pending certifications (finalization or both phase); auto-rejects students with failed certifications

See also: Student Performance → Certification (`05-student-performance.md`).

```admonish info "Future Extension: Scheduled Campaign Opening"
Currently, campaigns transition `draft → open` via manual teacher action. A future enhancement could add automatic opening via `registration_start` timestamp and background job. See [Future Extensions - Scheduled Opening](10-future-extensions.md#scheduled-campaign-opening) for details.
```

```admonish tip "UI hooks for unassigned"
After completion, the Campaign Show can surface an "Unassigned registrants"
table (name, matriculation, top preferences) with actions to place users into
groups via Roster Maintenance. In roster screens, add a filter
"Candidates from campaign X" that lists these unassigned users for quick moves.
```

### Campaign Lifecycle & Freezing Rules

Campaigns transition through several states to ensure data integrity and fair user experience. Certain attributes freeze at specific lifecycle points to prevent inconsistent or unfair changes.



**State Definitions:**
- **draft**: Campaign is being configured, not visible to students
- **open**: Registration window is active, students can register
- **closed**: Registration window ended (automatically at deadline or manually)
- **processing**: Allocation algorithm running (preference-based only)
- **completed**: Results published, rosters materialized

#### Freezing Rules

##### Campaign Attributes

| Attribute | Freeze Point | Modification Rules |
|-----------|--------------|-------------------|
| `allocation_mode` | After `draft` | Cannot change once opened. Students make decisions based on mode (early registration for FCFS vs. preference ranking). |
| `registration_opens_at` | After `draft` | Cannot change once opened. Opening time is in the past. |
| `registration_deadline` | Never | Can be extended anytime. Shortening is allowed but discouraged (confusing UX). |
| `planning_only` | Never | Can be toggled anytime. Affects internal behavior, not student-facing. |

##### Policies

| Action | Freeze Point | Modification Rules |
|--------|--------------|-------------------|
| Add/Edit/Remove | After `draft` | Cannot add, edit, or remove policies once opened. New policies could invalidate existing registrations (especially in FCFS where spots are already confirmed). |

##### Items

| Action | Freeze Point | Modification Rules |
|--------|--------------|-------------------|
| Add item | Never | Can always add new items. Gives students more options without invalidating existing choices. |
| Remove item | After `draft` | Cannot remove items with existing registrations. Students may have registered for (FCFS) or ranked (preference) that item. |

##### Capacity Constraints

| Mode | Freeze Point | Modification Rules |
|------|--------------|-------------------|
| FCFS | Constrained | Can increase anytime. Can decrease only if `new_capacity >= confirmed_count` for that item. Cannot revoke confirmed spots. |
| Preference-based | After `completed` | Can change freely while `draft`, `open`, or `closed` (allocation hasn't run). Freezes once `completed` (results published). |

#### Implementation Notes

**Validation Example:**
```ruby
validate :allocation_mode_frozen_after_open, on: :update
validate :policies_frozen_after_open, on: :update
validate :capacity_decrease_respects_confirmed, on: :update

def allocation_mode_frozen_after_open
  if allocation_mode_changed? && !draft?
    errors.add(:allocation_mode, "cannot be changed after campaign opens")
  end
end
```

**Item Removal:**
- Check `item.user_registrations.exists?` before allowing deletion
- Alternative: Soft-delete (set `active: false`) instead of destroying

**UI Feedback:**
- Disable/gray out frozen fields in forms
- Show tooltips explaining why changes are blocked
- Display warning before opening campaign: "Settings will be locked after opening"

```admonish warning "Reopening Campaigns"
When reopening a `completed` campaign (transitioning back to `open`), all freezing rules still apply. The campaign returns to accepting registrations, but fundamental settings (mode, policies, items) remain locked.
```

### Example Implementation (Phase-aware planned state)

```ruby
module Registration
  class Campaign < ApplicationRecord
    belongs_to :campaignable, polymorphic: true
    has_many :registration_items,
             class_name: "Registration::Item",
             dependent: :destroy
    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy
    has_many :registration_policies,
             class_name: "Registration::Policy",
             dependent: :destroy

    enum allocation_mode: { first_come_first_served: 0, preference_based: 1 }
    enum status: { draft: 0, open: 1, closed: 2, processing: 3, completed: 4 }

    validates :title, :registration_deadline, presence: true

    def evaluate_policies_for(user, phase: :registration)
      if phase == :registration
        return Registration::PolicyEngine::Result.new(pass: false, code: :campaign_not_open) unless open?
      end
      engine = Registration::PolicyEngine.new(self)
      engine.eligible?(user, phase: phase)
    end

    def policies_satisfied?(user, phase: :registration)
      evaluate_policies_for(user, phase: phase).pass
    end

    def open_for_registrations?
      open?
    end

    def finalize!
      return false if planning_only?
      return false unless closed? || processing?
      Registration::FinalizationGuard.new(self).check!
      Registration::AllocationMaterializer.new(self).materialize!
      update!(status: :completed)
    end

    def allocate!
      return false unless preference_based? && closed?
      update!(status: :processing)
      Registration::AllocationService.new(self, strategy: :min_cost_flow).allocate!
      true
    end

    def allocate_and_finalize!
      return false if planning_only?
      return false unless allocate!
      finalize!
    end

    def close!
      update!(status: :closed) if status == "open"
    end
  end
end
```

The system automatically calls `close!` when `registration_deadline` is reached via a scheduled job.

### Usage Scenarios

```admonish info
Entry points: Teacher/Editor starts at Campaigns index; Student starts at
Student Registration index.
```

- A **"Tutorial Registration" campaign** is created for a `Lecture`. It's `preference_based` and allows students to rank their preferred tutorial slots. Items point to `Tutorial`. (Admin UI: [Tutorial Show (open)](../mockups/campaigns_show_tutorial_open.html); Student UI: [Show – preference-based](../mockups/student_registration.html), [Confirmation](../mockups/student_registration_confirmation.html))
- A **"Talk Assignment" campaign** is created for a `Lecture` (often a seminar). It's `preference_based` or `first_come_first_served` and assigns talk slots. Items point to `Talk`.
- A **"Lecture Registration" campaign** is created for a `Lecture` (commonly seminars). It's typically `first_come_first_served` and enrolls students directly. The single item points to the `Lecture`. (Student UI: [Show – FCFS](../mockups/student_registration_fcfs.html))
- A **"Seminar Enrollment" campaign** is created for a `Lecture` (acting as a seminar). It's `first_come_first_served` to quickly fill the limited seminar seats. (Student UI: [Show – FCFS](../mockups/student_registration_fcfs.html))
- An **"Interest Registration" campaign** is created for a `Lecture` before the term to gauge demand (planning-only). It's `first_come_first_served` with a very high capacity; when it ends, you do not call `finalize!`. Results are used for hiring/planning and are not materialized to rosters. (Admin UI: [Interest Show (draft)](../mockups/campaigns_show_interest_draft.html))
- An **"Exam Registration" campaign** is created for an `Exam`. It is `first_come_first_served` and may include a `student_performance` policy (phase: `registration` or `both`) for advisory eligibility messaging; finalization enforces Certification=passed only if a finalization-phase `student_performance` policy exists. Items point to `Exam`. (Admin UI: [Exam Show](../mockups/campaigns_show_exam.html); Student UI: [Show – exam (FCFS)](../mockups/student_registration_fcfs_exam.html); see also [action required: institutional email](../mockups/student_registration_fcfs_exam_action_required_email.html))

---

### Planning-only campaigns (Interest Registration)

```admonish example "Planning-only Interest Registration"
Goal: Measure demand before a lecture starts to plan staffing (e.g., hire
tutors) without changing any rosters.

- Host: `Lecture` (campaignable).
- Items: Single item pointing to the `Lecture` (registerable).
- Mode: `first_come_first_served`.
- Capacity: Very high (effectively unlimited) to capture demand signal.
- Timing: Open well before the term; close before main registrations.
- Finalization: Do not invoke `finalize!`. No domain materialization occurs.
- Reporting: Use counts from `Registration::UserRegistration` (e.g.,
  confirmed) for planning and exports.

See also the Campaigns index mockups where the planning-only row appears as
"Interest Registration" with a note like "Planning only; not materialized".
```

## Registration::Campaignable (Concern)
**_The Campaign Host_**

```admonish info "What it represents"
A role for domain models (like `Lecture`) that allows them to 'host' or own registration campaigns.
```

```admonish note "Think of it as"
The 'container' for a set of related registration campaigns. A lecture 'contains' the campaign for its tutorials.
```

#### Responsibilities

- Provides a central point for grouping related campaigns.
- Simplifies finding campaigns related to a specific object (e.g., all registrations for a given lecture).

#### Example Implementation

```ruby
# app/models/concerns/registration/campaignable.rb
module Registration
  module Campaignable
    extend ActiveSupport::Concern

    included do
      has_many :registration_campaigns,
               as: :campaignable,
               class_name: "Registration::Campaign",
               dependent: :destroy
    end
  end
end
```

#### Implementations Here
- **`Lecture`**: Hosts campaigns for its tutorials or talks.
- **`Exam`**: Hosts a campaign for exam seat registration.

---

## Registration::Item (ActiveRecord Model)
**_The Selectable Catalog Entry_**

```admonish info "What it represents"
A selectable entry in a `Registration::Campaign`'s "catalog". Each entry points to a real-world `Registerable` object (like a `Tutorial` or `Talk`).
```

```admonish note "Think of it as"
- **Restaurant Analogy:** An item on a restaurant menu. The `Registerable` is the actual dish prepared in the kitchen. The `RegistrationItem` is the line on the menu for a specific day (the campaign). You order from the menu, not by pointing at the dish in the kitchen.

- **Teaching Analogy:** A slot in the registration system. The `Registerable` is the actual tutorial group that meets every Monday at 10am. The `RegistrationItem` is the entry for that tutorial in this semester's "Linear Algebra" registration (the campaign). Students sign up for the slot in the system, not by walking into the classroom.
```

The main fields and methods of `Registration::Item` are:

| Name/Field                | Type/Kind         | Description                                                              |
|---------------------------|-------------------|--------------------------------------------------------------------------|
| `registration_campaign_id`| DB column         | Foreign key for the parent campaign.                                     |
| `registerable_type`       | DB column         | Polymorphic type for the registerable object (e.g., `Tutorial`).         |
| `registerable_id`         | DB column         | Polymorphic ID for the registerable object.                              |
| `registration_campaign`   | Association       | The parent `Registration::Campaign`.                                      |
| `registerable`            | Association       | The underlying domain object (e.g., a `Tutorial` instance).              |
| `user_registrations`      | Association       | All user registrations (registration requests) for this item.            |
| `assigned_users`          | Method            | Returns users with confirmed registration (registration system data).    |
| `capacity`                | Method            | The maximum number of users, delegated from the `registerable`.          |


```ruby
module Registration
  class Item < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign"
    belongs_to :registerable, polymorphic: true
    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy

    def assigned_users
      user_registrations.confirmed.includes(:user).map(&:user)
    end
  end
end
```

### Usage Scenarios

Each scenario below is the item-side view of the campaign types listed
earlier. The `Registration::Item` belongs to the associated campaign and
wraps the concrete `registerable` record that users ultimately get
assigned to.

- **For a "Tutorial Registration" campaign:** A `RegistrationItem` is created for each `Tutorial` (e.g., "Tutorial A (Mon 10:00)"). The `registerable` association points to the `Tutorial` record.
- **For a "Talk Assignment" campaign:** A `RegistrationItem` is created for each `Talk` (e.g., "Talk: Machine Learning Advances"). The `registerable` association points to the `Talk` record.
- **For a "Lecture Registration" campaign:** A `RegistrationItem` is created for the lecture itself. The `registerable` association points to the `Lecture` record. This will be useful mostly when the lecture is a seminar. `Lecture` then has a dual role: as campaignable and as registerable.
- **For a "Cohort Registration" campaign:** A `RegistrationItem` is created for a `Cohort` (e.g., "Repeaters"). The `registerable` association points to the `Cohort` record.
- **For an "Exam Registration" campaign:** A `RegistrationItem` is created for the exam itself. The `registerable` association points to the `Exam` record. The campaign's `campaignable` is the parent `Lecture`. Each exam (Hauptklausur, Nachklausur, Wiederholungsklausur) gets its own campaign hosted by the lecture, with that exam as the sole registerable item.

```admonish warning "Registration::Item vs. Registration::Registerable"
It's crucial to understand the difference between these two concepts:

- **`Registration::Registerable`** is the **actual domain object** that a user is ultimately assigned to. Think of it as the real-world entity, like a `Tutorial` or a `Talk`. It's a role provided by a concern.

- **`Registration::Item`** is a **proxy or wrapper** that makes a registerable object available within a specific campaign. Think of it as a "listing in a catalog." If you have a "Tutorial Registration" campaign, you create one `Registration::Item` for each `Tutorial` that students can sign up for in that campaign.

Users register for a `Registration::Item`, not directly for a `Registerable`. This separation allows the same `Tutorial` to potentially be part of different campaigns over time without conflict.
```

---

## Registration::Registerable (Concern)
**_The Registration Target_**

```admonish info "What it represents"
A role for domain models (like `Tutorial` or `Talk`) that allows them to be the ultimate target of a registration.
```

```admonish note "Think of it as"
The actual group or event a user is enrolled in, such as a specific tutorial group or being assigned as the speaker for a talk.
```

#### Responsibilities
- Provide a capacity (fixed column or computed).
- Implement `materialize_allocation!(user_ids:, campaign:)` to apply confirmed results idempotently.
- Remain agnostic of solver or eligibility logic.

#### Not Responsibilities
- Eligibility checks (policies handle that).
- Storing pending registrations (that’s `UserRegistration`).
- Orchestrating allocation (that's the `Registration::Campaign`).

#### Public Interface
| Method                                      | Purpose                                                | Required |
|---------------------------------------------|--------------------------------------------------------|----------|
| `capacity`                                  | Integer seat count.                                    | Yes      |
| `materialize_allocation!(user_ids:, campaign:)` | Persists the authoritative roster for this campaign.   | Yes      |
| `allocated_user_ids`                        | Current materialized users from domain roster (delegates to roster system). | Yes |
| `remaining_capacity`, `full?`               | Convenience derived helpers.                           | Optional |

#### Example Implementation

```ruby
# app/models/concerns/registration/registerable.rb
module Registration
  module Registerable
    extend ActiveSupport::Concern

    def capacity
      self[:capacity] || raise(NotImplementedError, "#{self.class} must define #capacity")
    end

    def allocated_user_ids
      raise NotImplementedError, "#{self.class} must implement #allocated_user_ids to delegate to roster"
    end

    def remaining_capacity
      [capacity - allocated_user_ids.size, 0].max
    end

    def full?
      remaining_capacity.zero?
    end

    def materialize_allocation!(user_ids:, campaign:)
      raise NotImplementedError, "#{self.class} must implement #materialize_allocation!"
    end
  end
end
```

#### Implementation Details

The `Registration::Item` model uses `belongs_to :registerable, polymorphic: true`. Any model that includes the `Registration::Registerable` concern (e.g., `Tutorial`, `Talk`) becomes a valid target for this association.

The `materialize_allocation!` method is the most critical part of the interface. It is responsible for taking the final list of `user_ids` from the allocation process and persisting them into the domain model's own roster.

This method **must be idempotent**, meaning running it multiple times with the same `user_ids` and `campaign` produces the same result. A common pattern is to first remove all roster entries associated with the given `campaign` and then add the new ones, all within a single database transaction. Concrete examples are shown in the `Tutorial` and `Talk` sections later in this document.

The `allocated_user_ids` method **must be implemented** by each registerable model to delegate to its roster system. This returns the current materialized roster (domain data), as opposed to `Registration::Item#assigned_users` which returns users with confirmed registrations (registration system data). After finalization, these should match.


#### Usage Scenarios
- A **`Tutorial`** includes `Registerable` to manage its student roster.
- A **`Talk`** includes `Registerable` to designate students as its speakers.
- A **`Lecture`** (acting as a course) includes `Registerable` to manage direct enrollment.
- A **`Cohort`** includes `Registerable` to manage subgroups like "Repeaters".
- A future **`Exam`** model would include `Registerable` to manage allocation for an exam.

## Configuration Patterns

To ensure consistent rosters, the system encourages specific campaign combinations via the "New Campaign" wizard.

### Pattern 1: The "Group Track" (Standard)
Use this when your lecture has sub-groups (Tutorials or Talks).
- **Primary Campaign:** "Group Registration" (Items: All Tutorials/Talks).
- **Secondary Campaign (Optional):** "Special Groups" (Item: Cohort "Repeaters").
- **Roster Logic:** The Lecture Roster is the **union** of all Group members and Cohort members.

### Pattern 2: The "Enrollment Track" (Simple)
Use this when your lecture has no subgroups (e.g., Advanced Lecture, Ringvorlesung).
- **Primary Campaign:** "Course Enrollment" (Item: The Lecture itself).
- **Roster Logic:** The Lecture Roster is the list of registered students.

### Pattern 3: The "Mixed Track" (Discouraged)
It is possible to have both a "Group Registration" and a "Course Enrollment" campaign active simultaneously.
- **Use Case:** When lecture enrollment is technically required (e.g. for Moodle access) but groups are optional.
- **Implication:** This creates two parallel rosters. A student might be in a group but fail to register for the lecture.
- **System Behavior:** The wizard requires explicit acknowledgement to enable this track.

## Registration::Campaign (ActiveRecord Model)
**_The Registration Process Orchestrator_**

```admonish info "What it represents"
A time-bounded administrative process where users can register for specific items under a chosen mode.
```

```admonish tip "Think of it as"
“Tutorial Registration Week”, “Seminar Talk Selection Period”, “Exam Signup”
```

The main fields and methods of `Registration::Campaign` are:

| Name/Field                | Type/Kind         | Description                                                                                  |
|---------------------------|-------------------|----------------------------------------------------------------------------------------------|
| `campaignable_type`       | DB column         | Polymorphic type for the campaign host (e.g., Lecture)                                     |
| `campaignable_id`         | DB column         | Polymorphic ID for the campaign host                                                         |
| `title`                   | DB column         | Human-readable campaign title                                                                 |
| `allocation_mode`         | DB column (Enum)  | Registration mode: `first_come_first_served` or `preference_based`                            |
| `status`                  | DB column (Enum)  | Campaign state: `draft`, `open`, `closed`, `processing`, `completed`                        |
| `planning_only`           | DB column (Bool)  | Planning/reporting only; prevents materialization/finalization (default: false)              |
| `registration_deadline`   | DB column         | Deadline for user registrations (registration requests)                                      |
| `registration_items`      | Association       | Items available for registration within this campaign                                        |
| `user_registrations`      | Association       | User registrations (registration requests) for this campaign                                 |
| `registration_policies`   | Association       | Eligibility and other policies attached to this campaign                                     |
| `evaluate_policies_for(user, phase: :registration)` | Method      | Returns a structured eligibility result for the given phase (delegates to Policy Engine)                         |
| `policies_satisfied?(user, phase: :registration)` | Method      | Boolean convenience that returns true when all applicable policies pass                                 |
| `open_for_registrations?` | Method            | Returns true if campaign is currently accepting registrations                                 |
| `allocate!`               | Method            | Computes allocation (preference-based) without materialization                               |
| `finalize!`               | Method            | Enforces finalization-phase policies, then materializes the latest allocation into domain rosters                                       |
| `allocate_and_finalize!`  | Method            | Convenience: computes allocation and then finalizes                                          |

```admonish note
Eligibility is not a single field or method, but is determined dynamically by evaluating all active `registration_policies` for the campaign using the `evaluate_policies_for(user, phase:)` method, which delegates to the phase-aware policy engine. Use `policies_satisfied?(user, phase:)` as a boolean convenience.
```

```admonish tip "API at a glance"
- `evaluate_policies_for(user, phase: :registration)` → Result (fields: `pass`, `failed_policy`, `trace`, `details`)
- `policies_satisfied?(user, phase: :registration)` → Boolean (`true` when all applicable policies pass)
- `open_for_registrations?` → Boolean (campaign currently accepts registrations)

 See also: Controller endpoints in [Controller Architecture → Registration Controllers](11-controllers.md#registration-controllers).
```

### Behavior Highlights

- Guards registration window (`open?`)
- Delegates fine-grained eligibility to ordered `RegistrationPolicies` via Policy Engine
- Triggers solver (preference-based) after close (often at/after deadline)
- Finalizes and materializes allocation once only (idempotent)

#### Assigned vs Unassigned

- Assigned: the student has exactly one `confirmed` `Registration::UserRegistration` in the campaign after allocation/close.
- Unassigned: the student participated (has registrations) but has zero `confirmed` entries. On close/finalization, any remaining `pending` entries are normalized to `rejected` so the state is explicit.
- No extra tables are required. Helper methods on `Registration::Campaign` can expose `unassigned_user_ids`, `unassigned_users`, and `unassigned_count` computed from `UserRegistration` records.

```admonish note "Status semantics"
Statuses are mode-specific:
- First-come-first-served (FCFS): registrations are immediately `confirmed` or `rejected`.
- Preference-based: registrations are `pending` until allocation, then resolved to `confirmed` or `rejected` on finalize.

Do not overload `pending` to represent eligibility uncertainty in FCFS; use policy `details` (e.g., `stability`) purely for UI messaging.
```

#### Close vs Finalize

- **Close registration:** stops intake and edits; transitions `open → closed`.
  Used to lock the window early or when the deadline passes automatically.
- **Run allocation (preference-based only):** triggers solver; transitions `closed → processing`.
  FCFS campaigns skip this step (results already determined).
- **Finalize results:** before materialization, evaluates all active policies whose phase is `finalization` or `both` for each confirmed user (via a `Registration::FinalizationGuard`). A `student_performance` policy in finalization phase requires `Certification=passed` for all confirmed users. If any user fails a finalization-phase policy (or has missing/pending certification) the process aborts and status remains `processing` (or `closed` for FCFS) for remediation. After passing guards, materializes confirmed results and transitions to `completed`.
- **Planning-only campaigns:** close only; do not call `finalize!`. Results remain in reporting tables and are not materialized. When `planning_only` is true, `finalize!`/`allocate_and_finalize!` are no-ops.
- **Lecture performance completeness checks:**
  - **Campaign save:** Warns if any students lack certifications (any phase with student_performance policy)
  - **Campaign open:** Hard-fails if any students have missing/pending certifications (registration or both phase)
  - **Campaign finalize:** Hard-fails if any confirmed registrants have missing/pending certifications (finalization or both phase); auto-rejects students with failed certifications

See also: Student Performance → Certification (`05-student-performance.md`).

```admonish info "Future Extension: Scheduled Campaign Opening"
Currently, campaigns transition `draft → open` via manual teacher action. A future enhancement could add automatic opening via `registration_start` timestamp and background job. See [Future Extensions - Scheduled Opening](10-future-extensions.md#scheduled-campaign-opening) for details.
```

```admonish tip "UI hooks for unassigned"
After completion, the Campaign Show can surface an "Unassigned registrants"
table (name, matriculation, top preferences) with actions to place users into
groups via Roster Maintenance. In roster screens, add a filter
"Candidates from campaign X" that lists these unassigned users for quick moves.
```

### Campaign Lifecycle & Freezing Rules

Campaigns transition through several states to ensure data integrity and fair user experience. Certain attributes freeze at specific lifecycle points to prevent inconsistent or unfair changes.



**State Definitions:**
- **draft**: Campaign is being configured, not visible to students
- **open**: Registration window is active, students can register
- **closed**: Registration window ended (automatically at deadline or manually)
- **processing**: Allocation algorithm running (preference-based only)
- **completed**: Results published, rosters materialized

#### Freezing Rules

##### Campaign Attributes

| Attribute | Freeze Point | Modification Rules |
|-----------|--------------|-------------------|
| `allocation_mode` | After `draft` | Cannot change once opened. Students make decisions based on mode (early registration for FCFS vs. preference ranking). |
| `registration_opens_at` | After `draft` | Cannot change once opened. Opening time is in the past. |
| `registration_deadline` | Never | Can be extended anytime. Shortening is allowed but discouraged (confusing UX). |
| `planning_only` | Never | Can be toggled anytime. Affects internal behavior, not student-facing. |

##### Policies

| Action | Freeze Point | Modification Rules |
|--------|--------------|-------------------|
| Add/Edit/Remove | After `draft` | Cannot add, edit, or remove policies once opened. New policies could invalidate existing registrations (especially in FCFS where spots are already confirmed). |

##### Items

| Action | Freeze Point | Modification Rules |
|--------|--------------|-------------------|
| Add item | Never | Can always add new items. Gives students more options without invalidating existing choices. |
| Remove item | After `draft` | Cannot remove items with existing registrations. Students may have registered for (FCFS) or ranked (preference) that item. |

##### Capacity Constraints

| Mode | Freeze Point | Modification Rules |
|------|--------------|-------------------|
| FCFS | Constrained | Can increase anytime. Can decrease only if `new_capacity >= confirmed_count` for that item. Cannot revoke confirmed spots. |
| Preference-based | After `completed` | Can change freely while `draft`, `open`, or `closed` (allocation hasn't run). Freezes once `completed` (results published). |

#### Implementation Notes

**Validation Example:**
```ruby
validate :allocation_mode_frozen_after_open, on: :update
validate :policies_frozen_after_open, on: :update
validate :capacity_decrease_respects_confirmed, on: :update

def allocation_mode_frozen_after_open
  if allocation_mode_changed? && !draft?
    errors.add(:allocation_mode, "cannot be changed after campaign opens")
  end
end
```

**Item Removal:**
- Check `item.user_registrations.exists?` before allowing deletion
- Alternative: Soft-delete (set `active: false`) instead of destroying

**UI Feedback:**
- Disable/gray out frozen fields in forms
- Show tooltips explaining why changes are blocked
- Display warning before opening campaign: "Settings will be locked after opening"

```admonish warning "Reopening Campaigns"
When reopening a `completed` campaign (transitioning back to `open`), all freezing rules still apply. The campaign returns to accepting registrations, but fundamental settings (mode, policies, items) remain locked.
```

### Example Implementation (Phase-aware planned state)

```ruby
module Registration
  class Campaign < ApplicationRecord
    belongs_to :campaignable, polymorphic: true
    has_many :registration_items,
             class_name: "Registration::Item",
             dependent: :destroy
    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy
    has_many :registration_policies,
             class_name: "Registration::Policy",
             dependent: :destroy

    enum allocation_mode: { first_come_first_served: 0, preference_based: 1 }
    enum status: { draft: 0, open: 1, closed: 2, processing: 3, completed: 4 }

    validates :title, :registration_deadline, presence: true

    def evaluate_policies_for(user, phase: :registration)
      if phase == :registration
        return Registration::PolicyEngine::Result.new(pass: false, code: :campaign_not_open) unless open?
      end
      engine = Registration::PolicyEngine.new(self)
      engine.eligible?(user, phase: phase)
    end

    def policies_satisfied?(user, phase: :registration)
      evaluate_policies_for(user, phase: phase).pass
    end

    def open_for_registrations?
      open?
    end

    def finalize!
      return false if planning_only?
      return false unless closed? || processing?
      Registration::FinalizationGuard.new(self).check!
      Registration::AllocationMaterializer.new(self).materialize!
      update!(status: :completed)
    end

    def allocate!
      return false unless preference_based? && closed?
      update!(status: :processing)
      Registration::AllocationService.new(self, strategy: :min_cost_flow).allocate!
      true
    end

    def allocate_and_finalize!
      return false if planning_only?
      return false unless allocate!
      finalize!
    end

    def close!
      update!(status: :closed) if status == "open"
    end
  end
end
```

The system automatically calls `close!` when `registration_deadline` is reached via a scheduled job.

### Usage Scenarios

```admonish info
Entry points: Teacher/Editor starts at Campaigns index; Student starts at
Student Registration index.
```

- A **"Tutorial Registration" campaign** is created for a `Lecture`. It's `preference_based` and allows students to rank their preferred tutorial slots. Items point to `Tutorial`. (Admin UI: [Tutorial Show (open)](../mockups/campaigns_show_tutorial_open.html); Student UI: [Show – preference-based](../mockups/student_registration.html), [Confirmation](../mockups/student_registration_confirmation.html))
- A **"Talk Assignment" campaign** is created for a `Lecture` (often a seminar). It's `preference_based` or `first_come_first_served` and assigns talk slots. Items point to `Talk`.
- A **"Lecture Registration" campaign** is created for a `Lecture` (commonly seminars). It's typically `first_come_first_served` and enrolls students directly. The single item points to the `Lecture`. (Student UI: [Show – FCFS](../mockups/student_registration_fcfs.html))
- A **"Seminar Enrollment" campaign** is created for a `Lecture` (acting as a seminar). It's `first_come_first_served` to quickly fill the limited seminar seats. (Student UI: [Show – FCFS](../mockups/student_registration_fcfs.html))
- An **"Interest Registration" campaign** is created for a `Lecture` before the term to gauge demand (planning-only). It's `first_come_first_served` with a very high capacity; when it ends, you do not call `finalize!`. Results are used for hiring/planning and are not materialized to rosters. (Admin UI: [Interest Show (draft)](../mockups/campaigns_show_interest_draft.html))
- An **"Exam Registration" campaign** is created for an `Exam`. It is `first_come_first_served` and may include a `student_performance` policy (phase: `registration` or `both`) for advisory eligibility messaging; finalization enforces Certification=passed only if a finalization-phase `student_performance` policy exists. Items point to `Exam`. (Admin UI: [Exam Show](../mockups/campaigns_show_exam.html); Student UI: [Show – exam (FCFS)](../mockups/student_registration_fcfs_exam.html); see also [action required: institutional email](../mockups/student_registration_fcfs_exam_action_required_email.html))

---

### Planning-only campaigns (Interest Registration)

```admonish example "Planning-only Interest Registration"
Goal: Measure demand before a lecture starts to plan staffing (e.g., hire
tutors) without changing any rosters.

- Host: `Lecture` (campaignable).
- Items: Single item pointing to the `Lecture` (registerable).
- Mode: `first_come_first_served`.
- Capacity: Very high (effectively unlimited) to capture demand signal.
- Timing: Open well before the term; close before main registrations.
- Finalization: Do not invoke `finalize!`. No domain materialization occurs.
- Reporting: Use counts from `Registration::UserRegistration` (e.g.,
  confirmed) for planning and exports.

See also the Campaigns index mockups where the planning-only row appears as
"Interest Registration" with a note like "Planning only; not materialized".
```

## Registration::Campaignable (Concern)
**_The Campaign Host_**

```admonish info "What it represents"
A role for domain models (like `Lecture`) that allows them to 'host' or own registration campaigns.
```

```admonish note "Think of it as"
The 'container' for a set of related registration campaigns. A lecture 'contains' the campaign for its tutorials.
```

#### Responsibilities

- Provides a central point for grouping related campaigns.
- Simplifies finding campaigns related to a specific object (e.g., all registrations for a given lecture).

#### Example Implementation

```ruby
# app/models/concerns/registration/campaignable.rb
module Registration
  module Campaignable
    extend ActiveSupport::Concern

    included do
      has_many :registration_campaigns,
               as: :campaignable,
               class_name: "Registration::Campaign",
               dependent: :destroy
    end
  end
end
```

#### Implementations Here
- **`Lecture`**: Hosts campaigns for its tutorials or talks.
- **`Exam`**: Hosts a campaign for exam seat registration.

---

## Registration::Item (ActiveRecord Model)
**_The Selectable Catalog Entry_**

```admonish info "What it represents"
A selectable entry in a `Registration::Campaign`'s "catalog". Each entry points to a real-world `Registerable` object (like a `Tutorial` or `Talk`).
```

```admonish note "Think of it as"
- **Restaurant Analogy:** An item on a restaurant menu. The `Registerable` is the actual dish prepared in the kitchen. The `RegistrationItem` is the line on the menu for a specific day (the campaign). You order from the menu, not by pointing at the dish in the kitchen.

- **Teaching Analogy:** A slot in the registration system. The `Registerable` is the actual tutorial group that meets every Monday at 10am. The `RegistrationItem` is the entry for that tutorial in this semester's "Linear Algebra" registration (the campaign). Students sign up for the slot in the system, not by walking into the classroom.
```

The main fields and methods of `Registration::Item` are:

| Name/Field                | Type/Kind         | Description                                                              |
|---------------------------|-------------------|--------------------------------------------------------------------------|
| `registration_campaign_id`| DB column         | Foreign key for the parent campaign.                                     |
| `registerable_type`       | DB column         | Polymorphic type for the registerable object (e.g., `Tutorial`).         |
| `registerable_id`         | DB column         | Polymorphic ID for the registerable object.                              |
| `registration_campaign`   | Association       | The parent `Registration::Campaign`.                                      |
| `registerable`            | Association       | The underlying domain object (e.g., a `Tutorial` instance).              |
| `user_registrations`      | Association       | All user registrations (registration requests) for this item.            |
| `assigned_users`          | Method            | Returns users with confirmed registration (registration system data).    |
| `capacity`                | Method            | The maximum number of users, delegated from the `registerable`.          |


```ruby
module Registration
  class Item < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign"
    belongs_to :registerable, polymorphic: true
    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy

    def assigned_users
      user_registrations.confirmed.includes(:user).map(&:user)
    end
  end
end
```

### Usage Scenarios

Each scenario below is the item-side view of the campaign types listed
earlier. The `Registration::Item` belongs to the associated campaign and
wraps the concrete `registerable` record that users ultimately get
assigned to.

- **For a "Tutorial Registration" campaign:** A `RegistrationItem` is created for each `Tutorial` (e.g., "Tutorial A (Mon 10:00)"). The `registerable` association points to the `Tutorial` record.
- **For a "Talk Assignment" campaign:** A `RegistrationItem` is created for each `Talk` (e.g., "Talk: Machine Learning Advances"). The `registerable` association points to the `Talk` record.
- **For a "Lecture Registration" campaign:** A `RegistrationItem` is created for the lecture itself. The `registerable` association points to the `Lecture` record. This will be useful mostly when the lecture is a seminar. `Lecture` then has a dual role: as campaignable and as registerable.
- **For a "Cohort Registration" campaign:** A `RegistrationItem` is created for a `Cohort` (e.g., "Repeaters"). The `registerable` association points to the `Cohort` record.
- **For an "Exam Registration" campaign:** A `RegistrationItem` is created for the exam itself. The `registerable` association points to the `Exam` record. The campaign's `campaignable` is the parent `Lecture`. Each exam (Hauptklausur, Nachklausur, Wiederholungsklausur) gets its own campaign hosted by the lecture, with that exam as the sole registerable item.

```admonish warning "Registration::Item vs. Registration::Registerable"
It's crucial to understand the difference between these two concepts:

- **`Registration::Registerable`** is the **actual domain object** that a user is ultimately assigned to. Think of it as the real-world entity, like a `Tutorial` or a `Talk`. It's a role provided by a concern.

- **`Registration::Item`** is a **proxy or wrapper** that makes a registerable object available within a specific campaign. Think of it as a "listing in a catalog." If you have a "Tutorial Registration" campaign, you create one `Registration::Item` for each `Tutorial` that students can sign up for in that campaign.

Users register for a `Registration::Item`, not directly for a `Registerable`. This separation allows the same `Tutorial` to potentially be part of different campaigns over time without conflict.
```

---

## Registration::Registerable (Concern)
**_The Registration Target_**

```admonish info "What it represents"
A role for domain models (like `Tutorial` or `Talk`) that allows them to be the ultimate target of a registration.
```

```admonish note "Think of it as"
The actual group or event a user is enrolled in, such as a specific tutorial group or being assigned as the speaker for a talk.
```

#### Responsibilities
- Provide a capacity (fixed column or computed).
- Implement `materialize_allocation!(user_ids:, campaign:)` to apply confirmed results idempotently.
- Remain agnostic of solver or eligibility logic.

#### Not Responsibilities
- Eligibility checks (policies handle that).
- Storing pending registrations (that’s `UserRegistration`).
- Orchestrating allocation (that's the `Registration::Campaign`).

#### Public Interface
| Method                                      | Purpose                                                | Required |
|---------------------------------------------|--------------------------------------------------------|----------|
| `capacity`                                  | Integer seat count.                                    | Yes      |
| `materialize_allocation!(user_ids:, campaign:)` | Persists the authoritative roster for this campaign.   | Yes      |
| `allocated_user_ids`                        | Current materialized users from domain roster (delegates to roster system). | Yes |
| `remaining_capacity`, `full?`               | Convenience derived helpers.                           | Optional |

#### Example Implementation

```ruby
# app/models/concerns/registration/registerable.rb
module Registration
  module Registerable
    extend ActiveSupport::Concern

    def capacity
      self[:capacity] || raise(NotImplementedError, "#{self.class} must define #capacity")
    end

    def allocated_user_ids
      raise NotImplementedError, "#{self.class} must implement #allocated_user_ids to delegate to roster"
    end

    def remaining_capacity
      [capacity - allocated_user_ids.size, 0].max
    end

    def full?
      remaining_capacity.zero?
    end

    def materialize_allocation!(user_ids:, campaign:)
      raise NotImplementedError, "#{self.class} must implement #materialize_allocation!"
    end
  end
end
```

#### Implementation Details

The `Registration::Item` model uses `belongs_to :registerable, polymorphic: true`. Any model that includes the `Registration::Registerable` concern (e.g., `Tutorial`, `Talk`) becomes a valid target for this association.

The `materialize_allocation!` method is the most critical part of the interface. It is responsible for taking the final list of `user_ids` from the allocation process and persisting them into the domain model's own roster.

This method **must be idempotent**, meaning running it multiple times with the same `user_ids` and `campaign` produces the same result. A common pattern is to first remove all roster entries associated with the given `campaign` and then add the new ones, all within a single database transaction. Concrete examples are shown in the `Tutorial` and `Talk` sections later in this document.

The `allocated_user_ids` method **must be implemented** by each registerable model to delegate to its roster system. This returns the current materialized roster (domain data), as opposed to `Registration::Item#assigned_users` which returns users with confirmed registrations (registration system data). After finalization, these should match.


#### Usage Scenarios
- A **`Tutorial`** includes `Registerable` to manage its student roster.
- A **`Talk`** includes `Registerable` to designate students as its speakers.
- A **`Lecture`** (acting as a course) includes `Registerable` to manage direct enrollment.
- A **`Cohort`** includes `Registerable` to manage subgroups like "Repeaters".
- A future **`Exam`** model would include `Registerable` to manage allocation for an exam.

## Configuration Patterns

To ensure consistent rosters, the system encourages specific campaign combinations via the "New Campaign" wizard.

### Pattern 1: The "Group Track" (Standard)
Use this when your lecture has sub-groups (Tutorials or Talks).
- **Primary Campaign:** "Group Registration" (Items: All Tutorials/Talks).
- **Secondary Campaign (Optional):** "Special Groups" (Item: Cohort "Repeaters").
- **Roster Logic:** The Lecture Roster is the **union** of all Group members and Cohort members.

### Pattern 2: The "Enrollment Track" (Simple)
Use this when your lecture has no subgroups (e.g., Advanced Lecture, Ringvorlesung).
- **Primary Campaign:** "Course Enrollment" (Item: The Lecture itself).
- **Roster Logic:** The Lecture Roster is the list of registered students.

### Pattern 3: The "Mixed Track" (Discouraged)
It is possible to have both a "Group Registration" and a "Course Enrollment" campaign active simultaneously.
- **Use Case:** When lecture enrollment is technically required (e.g. for Moodle access) but groups are optional.
- **Implication:** This creates two parallel rosters. A student might be in a group but fail to register for the lecture.
- **System Behavior:** The wizard requires explicit acknowledgement to enable this track.

## Registration::Campaign (ActiveRecord Model)
**_The Registration Process Orchestrator_**

```admonish info "What it represents"
A time-bounded administrative process where users can register for specific items under a chosen mode.
```

```admonish tip "Think of it as"
“Tutorial Registration Week”, “Seminar Talk Selection Period”, “Exam Signup”
```

The main fields and methods of `Registration::Campaign` are:

| Name/Field                | Type/Kind         | Description                                                                                  |
|---------------------------|-------------------|----------------------------------------------------------------------------------------------|
| `campaignable_type`       | DB column         | Polymorphic type for the campaign host (e.g., Lecture)                                     |
| `campaignable_id`         | DB column         | Polymorphic ID for the campaign host                                                         |
| `title`                   | DB column         | Human-readable campaign title                                                                 |
| `allocation_mode`         | DB column (Enum)  | Registration mode: `first_come_first_served` or `preference_based`                            |
| `status`                  | DB column (Enum)  | Campaign state: `draft`, `open`, `closed`, `processing`, `completed`                        |
| `planning_only`           | DB column (Bool)  | Planning/reporting only; prevents materialization/finalization (default: false)              |
| `registration_deadline`   | DB column         | Deadline for user registrations (registration requests)                                      |
| `registration_items`      | Association       | Items available for registration within this campaign                                        |
| `user_registrations`      | Association       | User registrations (registration requests) for this campaign                                 |
| `registration_policies`   | Association       | Eligibility and other policies attached to this campaign                                     |
| `evaluate_policies_for(user, phase: :registration)` | Method      | Returns a structured eligibility result for the given phase (delegates to Policy Engine)                         |
| `policies_satisfied?(user, phase: :registration)` | Method      | Boolean convenience that returns true when all applicable policies pass                                 |
| `open_for_registrations?` | Method            | Returns true if campaign is currently accepting registrations                                 |
| `allocate!`               | Method            | Computes allocation (preference-based) without materialization                               |
| `finalize!`               | Method            | Enforces finalization-phase policies, then materializes the latest allocation into domain rosters                                       |
| `allocate_and_finalize!`  | Method            | Convenience: computes allocation and then finalizes                                          |

```admonish note
Eligibility is not a single field or method, but is determined dynamically by evaluating all active `registration_policies` for the campaign using the `evaluate_policies_for(user, phase:)` method, which delegates to the phase-aware policy engine. Use `policies_satisfied?(user, phase:)` as a boolean convenience.
```

```admonish tip "API at a glance"
- `evaluate_policies_for(user, phase: :registration)` → Result (fields: `pass`, `failed_policy`, `trace`, `details`)
- `policies_satisfied?(user, phase: :registration)` → Boolean (`true` when all applicable policies pass)
- `open_for_registrations?` → Boolean (campaign currently accepts registrations)

 See also: Controller endpoints in [Controller Architecture → Registration Controllers](11-controllers.md#registration-controllers).
```

### Behavior Highlights

- Guards registration window (`open?`)
- Delegates fine-grained eligibility to ordered `RegistrationPolicies` via Policy Engine
- Triggers solver (preference-based) after close (often at/after deadline)
- Finalizes and materializes allocation once only (idempotent)

#### Assigned vs Unassigned

- Assigned: the student has exactly one `confirmed` `Registration::UserRegistration` in the campaign after allocation/close.
- Unassigned: the student participated (has registrations) but has zero `confirmed` entries. On close/finalization, any remaining `pending` entries are normalized to `rejected` so the state is explicit.
- No extra tables are required. Helper methods on `Registration::Campaign` can expose `unassigned_user_ids`, `unassigned_users`, and `unassigned_count` computed from `UserRegistration` records.

```admonish note "Status semantics"
Statuses are mode-specific:
- First-come-first-served (FCFS): registrations are immediately `confirmed` or `rejected`.
- Preference-based: registrations are `pending` until allocation, then resolved to `confirmed` or `rejected` on finalize.

Do not overload `pending` to represent eligibility uncertainty in FCFS; use policy `details` (e.g., `stability`) purely for UI messaging.
```

#### Close vs Finalize

- **Close registration:** stops intake and edits; transitions `open → closed`.
  Used to lock the window early or when the deadline passes automatically.
- **Run allocation (preference-based only):** triggers solver; transitions `closed → processing`.
  FCFS campaigns skip this step (results already determined).
- **Finalize results:** before materialization, evaluates all active policies whose phase is `finalization` or `both` for each confirmed user (via a `Registration::FinalizationGuard`). A `student_performance` policy in finalization phase requires `Certification=passed` for all confirmed users. If any user fails a finalization-phase policy (or has missing/pending certification) the process aborts and status remains `processing` (or `closed` for FCFS) for remediation. After passing guards, materializes confirmed results and transitions to `completed`.
- **Planning-only campaigns:** close only; do not call `finalize!`. Results remain in reporting tables and are not materialized. When `planning_only` is true, `finalize!`/`allocate_and_finalize!` are no-ops.
- **Lecture performance completeness checks:**
  - **Campaign save:** Warns if any students lack certifications (any phase with student_performance policy)
  - **Campaign open:** Hard-fails if any students have missing/pending certifications (registration or both phase)
  - **Campaign finalize:** Hard-fails if any confirmed registrants have missing/pending certifications (finalization or both phase); auto-rejects students with failed certifications

See also: Student Performance → Certification (`05-student-performance.md`).

```admonish info "Future Extension: Scheduled Campaign Opening"
Currently, campaigns transition `draft → open` via manual teacher action. A future enhancement could add automatic opening via `registration_start` timestamp and background job. See [Future Extensions - Scheduled Opening](10-future-extensions.md#scheduled-campaign-opening) for details.
```

```admonish tip "UI hooks for unassigned"
After completion, the Campaign Show can surface an "Unassigned registrants"
table (name, matriculation, top preferences) with actions to place users into
groups via Roster Maintenance. In roster screens, add a filter
"Candidates from campaign X" that lists these unassigned users for quick moves.
```

### Campaign Lifecycle & Freezing Rules

Campaigns transition through several states to ensure data integrity and fair user experience. Certain attributes freeze at specific lifecycle points to prevent inconsistent or unfair changes.



**State Definitions:**
- **draft**: Campaign is being configured, not visible to students
- **open**: Registration window is active, students can register
- **closed**: Registration window ended (automatically at deadline or manually)
- **processing**: Allocation algorithm running (preference-based only)
- **completed**: Results published, rosters materialized

#### Freezing Rules

##### Campaign Attributes

| Attribute | Freeze Point | Modification Rules |
|-----------|--------------|-------------------|
| `allocation_mode` | After `draft` | Cannot change once opened. Students make decisions based on mode (early registration for FCFS vs. preference ranking). |
| `registration_opens_at` | After `draft` | Cannot change once opened. Opening time is in the past. |
| `registration_deadline` | Never | Can be extended anytime. Shortening is allowed but discouraged (confusing UX). |
| `planning_only` | Never | Can be toggled anytime. Affects internal behavior, not student-facing. |

##### Policies

| Action | Freeze Point | Modification Rules |
|--------|--------------|-------------------|
| Add/Edit/Remove | After `draft` | Cannot add, edit, or remove policies once opened. New policies could invalidate existing registrations (especially in FCFS where spots are already confirmed). |

##### Items

| Action | Freeze Point | Modification Rules |
|--------|--------------|-------------------|
| Add item | Never | Can always add new items. Gives students more options without invalidating existing choices. |
| Remove item | After `draft` | Cannot remove items with existing registrations. Students may have registered for (FCFS) or ranked (preference) that item. |

##### Capacity Constraints

| Mode | Freeze Point | Modification Rules |
|------|--------------|-------------------|
| FCFS | Constrained | Can increase anytime. Can decrease only if `new_capacity >= confirmed_count` for that item. Cannot revoke confirmed spots. |
| Preference-based | After `completed` | Can change freely while `draft`, `open`, or `closed` (allocation hasn't run). Freezes once `completed` (results published). |

#### Implementation Notes

**Validation Example:**
```ruby
validate :allocation_mode_frozen_after_open, on: :update
validate :policies_frozen_after_open, on: :update
validate :capacity_decrease_respects_confirmed, on: :update

def allocation_mode_frozen_after_open
  if allocation_mode_changed? && !draft?
    errors.add(:allocation_mode, "cannot be changed after campaign opens")
  end
end
```

**Item Removal:**
- Check `item.user_registrations.exists?` before allowing deletion
- Alternative: Soft-delete (set `active: false`) instead of destroying

**UI Feedback:**
- Disable/gray out frozen fields in forms
- Show tooltips explaining why changes are blocked
- Display warning before opening campaign: "Settings will be locked after opening"

```admonish warning "Reopening Campaigns"
When reopening a `completed` campaign (transitioning back to `open`), all freezing rules still apply. The campaign returns to accepting registrations, but fundamental settings (mode, policies, items) remain locked.
```

### Example Implementation (Phase-aware planned state)

```ruby
module Registration
  class Campaign < ApplicationRecord
    belongs_to :campaignable, polymorphic: true
    has_many :registration_items,
             class_name: "Registration::Item",
             dependent: :destroy
    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy
    has_many :registration_policies,
             class_name: "Registration::Policy",
             dependent: :destroy

    enum allocation_mode: { first_come_first_served: 0, preference_based: 1 }
    enum status: { draft: 0, open: 1, closed: 2, processing: 3, completed: 4 }

    validates :title, :registration_deadline, presence: true

    def evaluate_policies_for(user, phase: :registration)
      if phase == :registration
        return Registration::PolicyEngine::Result.new(pass: false, code: :campaign_not_open) unless open?
      end
      engine = Registration::PolicyEngine.new(self)
      engine.eligible?(user, phase: phase)
    end

    def policies_satisfied?(user, phase: :registration)
      evaluate_policies_for(user, phase: phase).pass
    end

    def open_for_registrations?
      open?
    end

    def finalize!
      return false if planning_only?
      return false unless closed? || processing?
      Registration::FinalizationGuard.new(self).check!
      Registration::AllocationMaterializer.new(self).materialize!
      update!(status: :completed)
    end

    def allocate!
      return false unless preference_based? && closed?
      update!(status: :processing)
      Registration::AllocationService.new(self, strategy: :min_cost_flow).allocate!
      true
    end

    def allocate_and_finalize!
      return false if planning_only?
      return false unless allocate!
      finalize!
    end

    def close!
      update!(status: :closed) if status == "open"
    end
  end
end
```

The system automatically calls `close!` when `registration_deadline` is reached via a scheduled job.

### Usage Scenarios

```admonish info
Entry points: Teacher/Editor starts at Campaigns index; Student starts at
Student Registration index.
```

- A **"Tutorial Registration" campaign** is created for a `Lecture`. It's `preference_based` and allows students to rank their preferred tutorial slots. Items point to `Tutorial`. (Admin UI: [Tutorial Show (open)](../mockups/campaigns_show_tutorial_open.html); Student UI: [Show – preference-based](../mockups/student_registration.html), [Confirmation](../mockups/student_registration_confirmation.html))
- A **"Talk Assignment" campaign** is created for a `Lecture` (often a seminar). It's `preference_based` or `first_come_first_served` and assigns talk slots. Items point to `Talk`.
- A **"Lecture Registration" campaign** is created for a `Lecture` (commonly seminars). It's typically `first_come_first_served` and enrolls students directly. The single item points to the `Lecture`. (Student UI: [Show – FCFS](../mockups/student_registration_fcfs.html))
- A **"Seminar Enrollment" campaign** is created for a `Lecture` (acting as a seminar). It's `first_come_first_served` to quickly fill the limited seminar seats. (Student UI: [Show – FCFS](../mockups/student_registration_fcfs.html))
- An **"Interest Registration" campaign** is created for a `Lecture` before the term to gauge demand (planning-only). It's `first_come_first_served` with a very high capacity; when it ends, you do not call `finalize!`. Results are used for hiring/planning and are not materialized to rosters. (Admin UI: [Interest Show (draft)](../mockups/campaigns_show_interest_draft.html))
- An **"Exam Registration" campaign** is created for an `Exam`. It is `first_come_first_served` and may include a `student_performance` policy (phase: `registration` or `both`) for advisory eligibility messaging; finalization enforces Certification=passed only if a finalization-phase `student_performance` policy exists. Items point to `Exam`. (Admin UI: [Exam Show](../mockups/campaigns_show_exam.html); Student UI: [Show – exam (FCFS)](../mockups/student_registration_fcfs_exam.html); see also [action required: institutional email](../mockups/student_registration_fcfs_exam_action_required_email.html))

---

### Planning-only campaigns (Interest Registration)

```admonish example "Planning-only Interest Registration"
Goal: Measure demand before a lecture starts to plan staffing (e.g., hire
tutors) without changing any rosters.

- Host: `Lecture` (campaignable).
- Items: Single item pointing to the `Lecture` (registerable).
- Mode: `first_come_first_served`.
- Capacity: Very high (effectively unlimited) to capture demand signal.
- Timing: Open well before the term; close before main registrations.
- Finalization: Do not invoke `finalize!`. No domain materialization occurs.
- Reporting: Use counts from `Registration::UserRegistration` (e.g.,
  confirmed) for planning and exports.

See also the Campaigns index mockups where the planning-only row appears as
"Interest Registration" with a note like "Planning only; not materialized".
```

## Registration::Campaignable (Concern)
**_The Campaign Host_**

```admonish info "What it represents"
A role for domain models (like `Lecture`) that allows them to 'host' or own registration campaigns.
```

```admonish note "Think of it as"
The 'container' for a set of related registration campaigns. A lecture 'contains' the campaign for its tutorials.
```

#### Responsibilities

- Provides a central point for grouping related campaigns.
- Simplifies finding campaigns related to a specific object (e.g., all registrations for a given lecture).

#### Example Implementation

```ruby
# app/models/concerns/registration/campaignable.rb
module Registration
  module Campaignable
    extend ActiveSupport::Concern

    included do
      has_many :registration_campaigns,
               as: :campaignable,
               class_name: "Registration::Campaign",
               dependent: :destroy
    end
  end
end
```

#### Implementations Here
- **`Lecture`**: Hosts campaigns for its tutorials or talks.
- **`Exam`**: Hosts a campaign for exam seat registration.

---

## Registration::Item (ActiveRecord Model)
**_The Selectable Catalog Entry_**

```admonish info "What it represents"
A selectable entry in a `Registration::Campaign`'s "catalog". Each entry points to a real-world `Registerable` object (like a `Tutorial` or `Talk`).
```

```admonish note "Think of it as"
- **Restaurant Analogy:** An item on a restaurant menu. The `Registerable` is the actual dish prepared in the kitchen. The `RegistrationItem` is the line on the menu for a specific day (the campaign). You order from the menu, not by pointing at the dish in the kitchen.

- **Teaching Analogy:** A slot in the registration system. The `Registerable` is the actual tutorial group that meets every Monday at 10am. The `RegistrationItem` is the entry for that tutorial in this semester's "Linear Algebra" registration (the campaign). Students sign up for the slot in the system, not by walking into the classroom.
```

The main fields and methods of `Registration::Item` are:

| Name/Field                | Type/Kind         | Description                                                              |
|---------------------------|-------------------|--------------------------------------------------------------------------|
| `registration_campaign_id`| DB column         | Foreign key for the parent campaign.                                     |
| `registerable_type`       | DB column         | Polymorphic type for the registerable object (e.g., `Tutorial`).         |
| `registerable_id`         | DB column         | Polymorphic ID for the registerable object.                              |
| `registration_campaign`   | Association       | The parent `Registration::Campaign`.                                      |
| `registerable`            | Association       | The underlying domain object (e.g., a `Tutorial` instance).              |
| `user_registrations`      | Association       | All user registrations (registration requests) for this item.            |
| `assigned_users`          | Method            | Returns users with confirmed registration (registration system data).    |
| `capacity`                | Method            | The maximum number of users, delegated from the `registerable`.          |


```ruby
module Registration
  class Item < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign"
    belongs_to :registerable, polymorphic: true
    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent:
    participant Campaign
    participant Item
    participant UserReg as UserRegistration
    participant PolicyEngine
    participant Roster as Domain Roster

    rect rgb(235, 245, 255)
    note over Student,PolicyEngine: Registration phase (campaign is open)
    Student->>UI: Visit campaign page
    UI->>Controller: GET /campaigns/:id
    Controller->>Campaign: find(campaign_id)
    Controller->>Campaign: open_for_registrations?
    Campaign-->>Controller: true

    Controller->>Campaign: evaluate_policies_for(user, phase: :registration)
    Campaign->>PolicyEngine: eligible?(user, phase: :registration)
    PolicyEngine-->>Campaign: Result(pass: true/false, ...)
    Campaign-->>Controller: Result

    alt policies fail
        Controller-->>UI: Ineligible state
        UI-->>Student: Show error: "Not eligible (reason)"
    else policies pass
        Controller-->>UI: Show register buttons
        UI-->>Student: Display available items

        Student->>UI: Click "Register for Item X"
        UI->>Controller: POST /campaigns/:id/user_registrations

        Controller->>Item: find(item_id)
        Controller->>Item: remaining_capacity
        Item-->>Controller: capacity count

        alt capacity available
            Controller->>UserReg: create!(status: :confirmed, ...)
            UserReg-->>Controller: registration record
            Controller-->>UI: Success
            UI-->>Student: "Registered successfully"
        else capacity exhausted
            Controller->>UserReg: create!(status: :rejected, ...)
            UserReg-->>Controller: registration record
            Controller-->>UI: Info: "No capacity"
            UI-->>Student: "Item full, registration rejected"
        end
    end
    end

    note over Student,Roster: Later: Admin closes campaign

    rect rgb(255, 245, 235)
    note over Student,Roster: View results (processing state)
    Student->>UI: View results
    UI->>Controller: GET /campaigns/:id
    Controller->>Campaign: status
    Campaign-->>Controller: :closed, :processing, or :completed
    Controller-->>UI: Show campaign with status
    UI-->>Student: Display confirmed/rejected
    end

    rect rgb(245, 255, 235)
    note over Controller,Roster: Optional: Admin finalizes (materialization)
    Controller->>Campaign: finalize!
    Campaign->>Campaign: evaluate_policies_for(confirmed_users, phase: :finalization)
    alt finalization policies fail
        Campaign-->>Controller: Error (stays in :processing)
    else finalization policies pass
        Campaign->>Item: materialize_allocation!(confirmed_user_ids)
        Item->>Roster: Update domain roster
        Roster-->>Item: Done
        Item-->>Campaign: Done
        Campaign->>Campaign: update!(status: :completed)
        Campaign-->>Controller: Success
    end
    end
```

---

## Proposed Folder Structure

To keep the new components organized according to Rails conventions, the new files would be placed as follows:

```text
app/
├── models/
│   ├── concerns/
│   │   └── registration/
│   │       ├── campaignable.rb
│   │       └── registerable.rb
│   └── registration/
│       ├── campaign.rb
│       ├── item.rb
│       ├── policy.rb
│       └── user_registration.rb
│
└── services/
  └── registration/
    ├── solvers/
    │   ├── min_cost_flow.rb
    │   └── cp_sat.rb (future)
    ├── allocation_service.rb
    ├── allocation_materializer.rb
    └── policy_engine.rb
```

This structure separates the ActiveRecord models, shared concerns, and business logic (service objects and solvers) into their conventional directories.

### Key Files
- `app/models/registration/campaign.rb` - Orchestrates the registration process
- `app/models/registration/user_registration.rb` - Records user registrations (registration requests)
- `app/models/registration/policy.rb` - Defines eligibility rules
- `app/services/registration/allocation_service.rb` - Runs allocation solver
- `app/services/registration/allocation_materializer.rb` - Persists results to domain models

---

## Database Tables

- `registration_campaigns` - Campaign orchestration records
- `registration_items` - Catalog entries linking campaigns to registerables
- `registration_user_registrations` - User registration request records with status and preference rank
- `registration_policies` - Eligibility rules with kind, phase, config, and position

```admonish note
Column details for each table are documented in the respective model sections above.
```