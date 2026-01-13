# Rosters

```admonish question "What is a 'Roster'?"
A "roster" is a list of names of people belonging to a particular group, team, or event.

- **Common Examples:** A class roster (a list of all students in a class), a team roster (a list of all players on a sports team), or a duty roster (a schedule showing who is working at what time).
- **In this context:** It refers to the official list of students enrolled in a tutorial or the list of speakers assigned to a seminar talk.
```

## The Core Concept: Lecture Roster as Superset

**Definition:**
The **Lecture Roster** (`lecture_memberships`) is the central registry for all students participating in a lecture. It acts as the single source of truth for authorization (who can access Moodle, videos, etc.) and communication.

**The Golden Rule:**
$$ \text{Current Group Members} \subseteq \text{Lecture Roster} $$

More precisely, the Lecture Roster contains **all current and former group members** due to sticky membership:
$$ \text{Lecture Roster} = \bigcup_{t \in \text{History}} \text{Members}_t(\text{Groups}) $$

**Behavioral Invariants:**
1.  **Upstream Propagation (Addition):**
    When a student is added to a group that propagates (**Tutorial**, **Talk**, or **Cohort with `propagate_to_lecture: true`**), they are **automatically** added to the Lecture Roster.
2.  **Sticky Membership (Removal from Group):**
    When a student is removed from a sub-group, they remain on the Lecture Roster. They transition to an "Unassigned" state within the lecture context. This preserves their history and access rights during group switches.
3.  **Cascading Deletion (Removal from Lecture):**
    When a student is removed from the Lecture Roster, they are **automatically** removed from all associated sub-groups.

### Cohort Propagation
**Cohorts** are flexible groups with configurable propagation via the `propagate_to_lecture` flag:
- **Propagating Cohorts** (`propagate_to_lecture: true`): Behave like Tutorials/Talks. Membership grants lecture access.
  - Example: Enrollment cohorts (`purpose: :enrollment`) for simple courses.
- **Non-Propagating Cohorts** (`propagate_to_lecture: false`): Act as "sidecars". Membership does NOT grant lecture access.
  - Example: Waitlists, planning cohorts (`purpose: :planning`).

**Purpose-Driven Behavior:**
- **Enrollment** (`purpose: :enrollment`): Must propagate. Acts as main enrollment path for simple courses.
- **General** (`purpose: :general`): Propagation configurable. Used for waitlists, special groups.
- **Planning** (`purpose: :planning`): Must not propagate. Used for demand surveys.

**Implementation Mechanism:**
Propagation is implemented via database triggers or callbacks on the cohort membership table:
1. **On Insert to `cohort_memberships`:** If `cohort.propagate_to_lecture` is true, automatically insert into `lecture_memberships` (idempotent).
2. **On Delete from `cohort_memberships`:** No action (sticky membership preserved).
3. **On Toggle of `propagate_to_lecture`:** When changed from false to true, bulk-insert all current cohort members into lecture roster. When changed from true to false, no removal (sticky membership).

This ensures Cohorts seamlessly integrate with the Superset Model without requiring manual service calls.

## The Unified Model: All Materialization Flows Through Groups

**Core Principle:** Every student enters the lecture roster via a **Group** (Tutorial, Talk, or Cohort). There is no direct lecture enrollment—simple courses use an **Enrollment Cohort** (`purpose: :enrollment`, `propagate_to_lecture: true`).

### Pattern 1: Complex Courses (Tutorials/Talks)
*   **Use Case:** Large lectures with tutorials or seminars with multiple talks.
*   **Workflow:**
    1.  **Main Campaign:** Students register for Tutorials/Talks. Materialization grants them access via Upstream Propagation.
    2.  **Sidecars (Optional):** "Waitlist" or "Latecomer" Cohorts (`propagate_to_lecture: false`) collect students separately. These students do not get access until staff manually moves them to a Tutorial.
*   **Result:** The Lecture Roster is the union of all Tutorials/Talks plus any students from propagating cohorts.

### Pattern 2: Simple Courses (Enrollment Cohort)
*   **Use Case:** Lectures without tutorials (e.g., advanced seminars, standalone courses).
*   **Workflow:**
    1.  **Main Campaign:** Students register for an **Enrollment Cohort** (`purpose: :enrollment`, `propagate_to_lecture: true`).
    2.  **Quick-Create:** Teacher creates this cohort via "Enable Simple Enrollment" button in Roster Overview.
*   **Result:** The Lecture Roster contains members of the enrollment cohort. Technically identical to Pattern 1 with one group.

### Pattern 3: Demand Forecasting (Planning Cohort)
*   **Use Case:** Gauge interest before the semester without granting access.
*   **Workflow:**
    1.  **Survey Campaign:** Students register for a **Planning Cohort** (`purpose: :planning`, `propagate_to_lecture: false`).
    2.  **Repeatable:** Multiple planning cohorts allowed per lecture (e.g., "Oct Survey", "Nov Survey").
*   **Result:** Cohort roster is materialized but doesn't propagate to lecture. Used for staffing decisions.

### Mixing Patterns

It is valid to mix groups in one campaign:
*   **Tutorial + Waitlist Cohort:** Main allocation to tutorials, overflow to non-propagating waitlist.
*   **Talk + Audit Cohort:** Talk selection with audit listener option (non-propagating).
*   **Enrollment Cohort + Late Registration Cohort:** Multiple cohorts feeding into the same lecture.

**Key:** Propagation flag determines behavior. System handles idempotency automatically.



---

## Roster::Rosterable (Concern)
**_The Universal Roster API_**

```admonish info "What it represents"
A concern that gives any `Registration::Registerable` model a uniform roster management interface.
```

```admonish note "Think of it as"
The “contract” required by the maintenance service, defining how to read and write to a model's roster.
```

### Public Interface & Contract

| Method | Provided/Required | Description |
|---|---|---|
| `roster_user_ids` | **Required (Override)** | Returns the current list of user IDs on the roster as an `Array<Integer>`. |
| `replace_roster!(user_ids:)` | **Required (Override)** | Atomically replaces the entire roster with the given list of user IDs. |
| `roster_entries` | **Required (Override)** | Returns an ActiveRecord relation to the join table for campaign tracking. |
| `mark_campaign_source!(user_ids, campaign)` | **Required (Override)** | Marks the given user roster entries as sourced from the specified campaign. |
| `allocated_user_ids` | Provided | Delegates to `roster_user_ids` to satisfy `Registration::Registerable` contract. |
| `materialize_allocation!(user_ids:, campaign:)` | Provided | Implements the allocation materialization from `Registration::Registerable`. |
| `add_user_to_roster!(user_id)` | Provided (private) | Adds a single user to the roster if not already present. |
| `remove_user_from_roster!(user_id)` | Provided (private) | Removes a single user from the roster. |
| `self_materialization_mode` | Provided (enum) | Controls student self-service roster access: `disabled`, `add_only`, `remove_only`, `add_and_remove`. |
| `can_self_add?(user)` | Provided | Checks if user can join via self-materialization. |
| `can_self_remove?(user)` | Provided | Checks if user can leave via self-materialization. |
| `self_add!(user)` | Provided | Student-initiated roster join (with permission check). |
| `self_remove!(user)` | Provided | Student-initiated roster leave (with permission check). |

### Behavior Highlights
- **Explicit Contract:** The concern raises a `NotImplementedError` if an including class fails to override required methods (`#roster_user_ids`, `#replace_roster!`, `#roster_entries`, `#mark_campaign_source!`), ensuring the contract is met.
- **Idempotent:** Calling `replace_roster!` with the same set of IDs should result in no change.
- **Registration Integration:** Provides `allocated_user_ids` and `materialize_allocation!` to satisfy the `Registration::Registerable` interface, allowing rosters to be managed by the registration system.
- **Campaign Tracking:** The `materialize_allocation!` method preserves manually-added roster entries while replacing campaign-sourced entries, using the `source_campaign` field on join table records.
- **Self-Materialization:** Enables student-initiated roster changes as an alternative to campaigns or post-campaign follow-up. Default is `disabled` (staff-only access).

### Example Implementation
```ruby
# filepath: app/models/concerns/roster/rosterable.rb
module Roster
  module Rosterable
    extend ActiveSupport::Concern

    included do
      enum self_materialization_mode: {
        disabled: 0,
        add_only: 1,
        remove_only: 2,
        add_and_remove: 3
      }, _prefix: :self_mat

      validate :self_materialization_not_during_active_campaign
    end

    def roster_user_ids
      raise NotImplementedError, "#{self.class.name} must implement #roster_user_ids"
    end

    def replace_roster!(user_ids:)
      raise NotImplementedError, "#{self.class.name} must implement #replace_roster!"
    end

    def allocated_user_ids
      roster_user_ids
    end

    def materialize_allocation!(user_ids:, campaign:)
      transaction do
        current_ids = roster_user_ids
        campaign_sourced_ids = current_ids.select do |uid|
          roster_entries.exists?(user_id: uid, source_campaign: campaign)
        end

        other_ids = current_ids - campaign_sourced_ids
        new_ids = (other_ids + user_ids).uniq

        replace_roster!(user_ids: new_ids)
        mark_campaign_source!(user_ids, campaign)
      end
    end

    def can_self_add?(user)
      return false if self_mat_disabled? || self_mat_remove_only?
      return false if full?
      !roster_user_ids.include?(user.id)
    end

    def can_self_remove?(user)
      return false if self_mat_disabled? || self_mat_add_only?
      roster_user_ids.include?(user.id)
    end

    def self_add!(user)
      raise "Not allowed" unless can_self_add?(user)
      add_user_to_roster!(user.id)
    end

    def self_remove!(user)
      raise "Not allowed" unless can_self_remove?(user)
      remove_user_from_roster!(user.id)
    end

    private

    def add_user_to_roster!(user_id)
      ids = roster_user_ids
      return if ids.include?(user_id)
      replace_roster!(user_ids: ids + [user_id])
    end

    def remove_user_from_roster!(user_id)
      replace_roster!(user_ids: roster_user_ids - [user_id])
    end

    def roster_entries
      raise NotImplementedError, "#{self.class.name} must implement #roster_entries for campaign tracking"
    end

    def mark_campaign_source!(user_ids, campaign)
      raise NotImplementedError, "#{self.class.name} must implement #mark_campaign_source! for campaign tracking"
    end

    def self_materialization_not_during_active_campaign
      return if self_mat_disabled?

      active = Registration::Item.where(registerable: self)
        .joins(:registration_campaign)
        .where.not(registration_campaigns: {
          status: :completed
        }).exists?

      if active
        errors.add(:self_materialization_mode,
          "cannot be enabled during active campaign")
      end
    end
  end
end
```

### Usage Scenarios
- `Tutorial` and `Talk` both include `Roster::Rosterable`.
- `Tutorial` implements `roster_user_ids` by reading from a new `tutorial_memberships` join table (to be created).
- `Talk` implements `replace_roster!` using its existing `speaker_talk_joins` association.

---

## Roster::MaintenanceService
**_Staff Maintenance_**

```admonish info "What it represents"
The single, safe entry point for all staff-initiated roster changes after an allocation is complete.
```

```admonish note "Think of it as"
An admin “move/add/remove” service with capacity checks and logging.
```

```admonish note "How this is different from Registration::AllocationService"
- `Registration::AllocationService` is the **automated solver** that runs once to create the initial allocation.
- `Roster::MaintenanceService` is the **manual tool** for staff to make individual changes to rosters *after* the campaign is finished.
```

### Public Interface

| Method | Description |
|---|---|
| `initialize(actor:)` | Sets up the service with the acting user for auditing. |
| `move_user!(user_id:, from:, to:, ...)` | Atomically moves a user from one `Roster::Rosterable` to another. |
| `add_user!(user_id:, to:, ...)` | Adds a user to a `Roster::Rosterable`. |
| `remove_user!(user_id:, from:, ...)` | Removes a user from a `Roster::Rosterable`. |

### Behavior Highlights
- **Transactional:** All operations, especially `move_user!`, are performed within a database transaction to ensure atomicity.
- **Capacity Enforcement:** Enforces the `capacity` of the target `Roster::Rosterable` unless an `allow_overfill: true` flag is passed.
- **Auditing Hook:** Calls a `log()` method to provide a hook for future audit trail implementation.
- **Denormalization:** Can update denormalized counters like `Registration::Item.assigned_count` to keep dashboards in sync.

### Example Implementation
```ruby
# filepath: app/services/roster/maintenance_service.rb
class Roster::MaintenanceService
  def initialize(actor:)
    @actor = actor
  end

  def move_user!(user_id:, from:, to:, allow_overfill: false, reason: nil)
    raise ArgumentError, "type mismatch" unless from.class == to.class
    ActiveRecord::Base.transaction do
      enforce_capacity!(to) unless allow_overfill
      from.send(:remove_user_from_roster!, user_id)
      to.send(:add_user_to_roster!, user_id)
      touch_counts!(from, to)
      log(:move, user_id: user_id, from: from, to: to, reason: reason)
    end
  end

  def add_user!(user_id:, to:, allow_overfill: false, reason: nil)
    ActiveRecord::Base.transaction do
      enforce_capacity!(to) unless allow_overfill
      to.send(:add_user_to_roster!, user_id)
      touch_counts!(to)
      log(:add, user_id: user_id, to: to, reason: reason)
    end
  end

  def remove_user!(user_id:, from:, reason: nil)
    ActiveRecord::Base.transaction do
      from.send(:remove_user_from_roster!, user_id)
      touch_counts!(from)
      log(:remove, user_id: user_id, from: from, reason: reason)
    end
  end

  private

  def enforce_capacity!(rosterable)
    raise "Capacity reached" if rosterable.full?
  end

  def touch_counts!(*rosterables)
    # Logic to find associated Registration::Items and update assigned_count
  end

  def log(action, **data)
    # Hook for future auditing (e.g., create RosterChangeEvent record)
  end
end
```

### Usage Scenarios
- **Moving a student:** An administrator moves a student from a full tutorial to one with free space.
  ```ruby
  service = Roster::MaintenanceService.new(actor: current_admin)
  tutorial_from = Tutorial.find(1)
  tutorial_to = Tutorial.find(2)
  student_id = 123
  service.move_user!(user_id: student_id, from: tutorial_from, to: tutorial_to, reason: "Balancing class sizes")
  ```

- **Adding a late-comer:** A student who missed the deadline is manually added to a tutorial.
  ```ruby
  service = Roster::MaintenanceService.new(actor: current_admin)
  tutorial = Tutorial.find(5)
  student_id = 456
  service.add_user!(user_id: student_id, to: tutorial, reason: "Late registration approved by professor")
  ```

- **Removing a dropout:** A student officially drops the course.
  ```ruby
  service = Roster::MaintenanceService.new(actor: current_admin)
  tutorial = Tutorial.find(3)
  student_id = 789
  service.remove_user!(user_id: student_id, from: tutorial, reason: "Student dropped course")
  ```

---

## Enhanced Domain Models

The following sections describe how existing MaMpf models are enhanced to integrate with the roster management system by implementing the `Rosterable` concern.

### Tutorial (Enhanced)
**_A Rosterable Target_**

```admonish info "What it represents"
An existing MaMpf tutorial model, enhanced to manage its student list.
```

#### Rosterable Implementation
The `Tutorial` model includes the `Roster::Rosterable` concern to provide a standard interface for managing its student roster via a join table.

| Method | Implementation Detail |
|---|---|
| `roster_user_ids` | Plucks `user_id`s from the `tutorial_memberships` join table (to be created). |
| `replace_roster!(user_ids:)` | Deletes existing memberships and creates new ones in a transaction. |

#### Example Implementation
```ruby
# filepath: app/models/tutorial.rb
class Tutorial < ApplicationRecord
  include Registration::Registerable
  include Roster::Rosterable

  has_many :tutorial_memberships, dependent: :destroy
  has_many :students, through: :tutorial_memberships, source: :user

  def roster_user_ids
    tutorial_memberships.pluck(:user_id)
  end

  def replace_roster!(user_ids:)
    TutorialMembership.transaction do
      tutorial_memberships.delete_all
      user_ids.each { |uid| tutorial_memberships.create!(user_id: uid) }
    end
  end

  def roster_entries
    tutorial_memberships
  end

  def mark_campaign_source!(user_ids, campaign)
    tutorial_memberships.where(user_id: user_ids)
                       .update_all(source_campaign_id: campaign.id)
  end
end
```

The `tutorial_memberships` table should include a `source_campaign_id` column (nullable) to track which campaign materialized each roster entry.

---

### Talk (Enhanced)
**_A Rosterable Target_**

```admonish info "What it represents"
An existing MaMpf talk model, enhanced to manage its speaker list.
```

#### Rosterable Implementation
The `Talk` model includes the `Roster::Rosterable` concern to provide a standard interface for managing its speakers.

| Method | Implementation Detail |
|---|---|
| `roster_user_ids` | Plucks `speaker_id`s from the `speaker_talk_joins` join table. |
| `replace_roster!(user_ids:)` | Deletes existing joins and creates new ones in a transaction. |

#### Example Implementation
```ruby
# filepath: app/models/talk.rb
class Talk < ApplicationRecord
  include Registration::Registerable
  include Roster::Rosterable

  has_many :speaker_talk_joins, dependent: :destroy
  has_many :speakers, through: :speaker_talk_joins

  def roster_user_ids
    speaker_talk_joins.pluck(:speaker_id)
  end

  def replace_roster!(user_ids:)
    SpeakerTalkJoin.transaction do
      speaker_talk_joins.delete_all
      user_ids.each { |uid| speaker_talk_joins.create!(speaker_id: uid) }
    end
  end

  def roster_entries
    speaker_talk_joins
  end

  def mark_campaign_source!(user_ids, campaign)
    speaker_talk_joins.where(speaker_id: user_ids)
                      .update_all(source_campaign_id: campaign.id)
  end
end
```

The `speaker_talk_joins` table should include a `source_campaign_id` column (nullable) to track which campaign materialized each speaker assignment.

---

### Cohort (Rosterable Implementation)
**_A Rosterable Target_**

```admonish info "What it represents"
A generic group of students, managed via `cohort_memberships`.
```

#### Rosterable Implementation
The `Cohort` model includes the `Roster::Rosterable` concern.

| Method | Implementation Detail |
|---|---|
| `roster_user_ids` | Plucks `user_id`s from the `cohort_memberships` join table. |
| `replace_roster!(user_ids:)` | Deletes existing memberships and creates new ones. |

#### Example Implementation
```ruby
class Cohort < ApplicationRecord
  include Registration::Registerable
  include Roster::Rosterable

  belongs_to :context, polymorphic: true
  has_many :cohort_memberships, dependent: :destroy
  has_many :members, through: :cohort_memberships, source: :user

  def roster_user_ids
    cohort_memberships.pluck(:user_id)
  end

  def replace_roster!(user_ids:)
    CohortMembership.transaction do
      cohort_memberships.delete_all
      user_ids.each { |uid| cohort_memberships.create!(user_id: uid) }
    end
  end

  def roster_entries
    cohort_memberships
  end

  def mark_campaign_source!(user_ids, campaign)
    cohort_memberships.where(user_id: user_ids)
                      .update_all(source_campaign_id: campaign.id)
  end
end
```

---

### Lecture (Enhanced)
**_The Central Roster Hub_**

```admonish info "What it represents"
The lecture roster is the authoritative list of all students with access to lecture materials, Moodle, videos, etc. It serves as the **superset** that all sub-group rosters (Tutorials, Talks, Cohorts) propagate into.
```

#### Rosterable Implementation
The `Lecture` model includes the `Roster::Rosterable` concern to manage the central student roster.

| Method | Implementation Detail |
|---|---|
| `roster_user_ids` | Plucks `user_id`s from the `lecture_memberships` join table (existing). |
| `replace_roster!(user_ids:)` | Deletes existing memberships and creates new ones in a transaction. |

#### Behavioral Notes
- **Never Materialized Directly:** Lectures do NOT include `Registration::Registerable`. They only receive students via **Upstream Propagation** from sub-groups.
- **Sticky Membership:** Students remain in the lecture roster even after leaving all sub-groups. Manual removal via `Roster::MaintenanceService` is required.
- **Cascading Deletion:** When a student is removed from the lecture roster, they are automatically removed from all sub-groups (Tutorials, Talks, Cohorts).

#### Example Implementation
```ruby
class Lecture < ApplicationRecord
  include Registration::Campaignable
  include Roster::Rosterable

  has_many :lecture_memberships, dependent: :destroy
  has_many :students, through: :lecture_memberships, source: :user

  has_many :tutorials
  has_many :talks
  has_many :cohorts, as: :context

  def roster_user_ids
    lecture_memberships.pluck(:user_id)
  end

  def replace_roster!(user_ids:)
    LectureMembership.transaction do
      lecture_memberships.delete_all
      user_ids.each { |uid| lecture_memberships.create!(user_id: uid) }
    end
  end

  def roster_entries
    lecture_memberships
  end

  def mark_campaign_source!(user_ids, campaign)
    lecture_memberships.where(user_id: user_ids)
                       .update_all(source_campaign_id: campaign.id)
  end
end
```

The `lecture_memberships` table should include a `source_campaign_id` column (nullable) to track which campaign initially granted access (via which sub-group).

```admonish warning "Cascading Deletion Hook"
The `Lecture` model should implement an `after_destroy` callback on `lecture_memberships` to cascade deletions to all sub-group rosters:

~~~ruby
after_destroy :cascade_to_subgroups, if: :will_save_change_to_user_id?

def cascade_to_subgroups
  tutorials.each { |t| t.roster_entries.where(user_id: user_id).destroy_all }
  talks.each { |t| t.roster_entries.where(user_id: user_id).destroy_all }
  cohorts.each { |c| c.roster_entries.where(user_id: user_id).destroy_all }
end
~~~
```

---

## ERD for Roster Implementations

This diagram shows the concrete database relationships for the `Roster::Rosterable` implementations. The `Roster::Rosterable` concern provides a uniform API over these different underlying structures.

```mermaid
erDiagram
    LECTURE ||--o{ LECTURE_MEMBERSHIP : "has (existing)"
    LECTURE_MEMBERSHIP }o--|| USER : "links to"

    LECTURE ||--o{ TUTORIAL : "has many"
    TUTORIAL ||--o{ TUTORIAL_MEMBERSHIP : "has (to be created)"
    TUTORIAL_MEMBERSHIP }o--|| USER : "links to"

    LECTURE ||--o{ TALK : "has many"
    TALK ||--o{ SPEAKER_TALK_JOIN : "has (existing)"
    SPEAKER_TALK_JOIN }o--|| USER : "links to"

    LECTURE ||--o{ COHORT : "has many (context)"
    COHORT ||--o{ COHORT_MEMBERSHIP : "has (new)"
    COHORT_MEMBERSHIP }o--|| USER : "links to"
    COHORT {
        boolean propagate_to_lecture "Triggers upstream propagation"
        int purpose "general=0, enrollment=1, planning=2"
    }
```

**Propagation Rules:**
- **Tutorials & Talks:** Always propagate to Lecture roster (automatic)
- **Cohorts:** Propagate only if `propagate_to_lecture: true` (configurable)
- **Sticky Membership:** Removal from sub-group does NOT remove from Lecture roster

---

## Sequence Diagram

This diagram shows the two distinct phases: the initial, automated materialization of the roster, followed by ongoing manual maintenance by staff. It also illustrates the upstream propagation from sub-groups to the lecture roster.

```mermaid
sequenceDiagram
    actor Admin
    participant Campaign as Registration::Campaign
    participant Materializer as Registration::AllocationMaterializer
    participant RosterService as Roster::MaintenanceService
    participant SubGroup as Roster::Rosterable (e.g., Tutorial)
    participant Lecture as Lecture Roster

    rect rgb(235, 245, 255)
    note over Campaign,Lecture: Phase 1: Automated Materialization
    Campaign->>Materializer: new(campaign).materialize!
    Materializer->>SubGroup: materialize_allocation!(user_ids:, campaign:)
    note right of SubGroup: From Registration::Registerable
    SubGroup->>SubGroup: 1. Query current roster_user_ids
    SubGroup->>SubGroup: 2. Identify campaign-sourced entries
    SubGroup->>SubGroup: 3. Merge with new user_ids
    SubGroup->>SubGroup: 4. Call replace_roster!(merged_ids)
    SubGroup->>SubGroup: 5. Mark new entries with source_campaign_id
    
    alt Tutorial or Talk (always propagates)
        SubGroup->>Lecture: Trigger: Add users to lecture roster
        note right of Lecture: Upstream Propagation (automatic)
    else Cohort with propagate_to_lecture: true
        SubGroup->>Lecture: Trigger: Add users to lecture roster
        note right of Lecture: Upstream Propagation (configured)
    else Cohort with propagate_to_lecture: false
        note right of SubGroup: No propagation (planning/waitlist)
    end
    end

    note over Admin, Lecture: ... time passes ...

    rect rgb(255, 245, 235)
    note over Admin,Lecture: Phase 2: Manual Roster Maintenance
    Admin->>RosterService: new(actor: admin).move_user!(...)
    RosterService->>SubGroup: from.remove_user_from_roster!(user_id)
    RosterService->>SubGroup: to.add_user_to_roster!(user_id)
    note right of SubGroup: Uses private methods from Roster::Rosterable concern
    SubGroup->>Lecture: Trigger: Add user to lecture roster (if propagates)
    note right of Lecture: Sticky membership preserved
    end
```

## Proposed Folder Structure

To keep the new components organized, the new files would be placed as follows:

```text
app/
├── models/
│   └── concerns/
│       └── roster/
│           └── rosterable.rb
│
└── services/
    └── roster/
        └── maintenance_service.rb
```

### Key Files
- `app/models/concerns/roster/rosterable.rb` - Uniform roster API concern
- `app/services/roster/maintenance_service.rb` - Manual roster modification service

---

## Database Tables

The roster system doesn't introduce new database tables. Instead, it provides a uniform API over existing and to-be-created join tables:

- `tutorial_memberships` (to be created) - Join table for tutorial student rosters
- `speaker_talk_joins` (existing) - Join table for talk speaker assignments
- `cohort_memberships` (to be created) - Join table for cohort student memberships

```admonish note
The `Roster::Rosterable` concern provides a uniform interface (`roster_user_ids`, `replace_roster!`) regardless of the underlying table structure. Column details are shown in the example implementations above.
```

