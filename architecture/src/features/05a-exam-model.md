# Exam Model

```admonish question "What is an 'Exam'?"
An exam is a scheduled assessment event where students demonstrate their knowledge under controlled conditions.

- **Common Examples:** "Final Exam Linear Algebra", "Midterm Calculus", "Retake Exam Analysis"
- **In this context:** A new domain model that acts as a registration target (students sign up for exam slots), manages rosters (tracking who is registered), and links to the assessment system for grading. Exams belong to a lecture.
```

## Problem Overview
MaMpf needs a formal representation of exams that can:
- Act as a registration target with capacity limits and eligibility checks (see [Student Performance](05-student-performance.md))
- Track which students are registered for which exam dates/locations
- Link to the assessment system for grading
- Support multiple exam dates per lecture (e.g., Hauptklausur, Nachklausur, Wiederholungsklausur)

## Solution Architecture
We introduce a new `Exam` model that:
- **Belongs to a `Lecture`**: Each exam is scoped to a specific lecture offering
- **Implements `Registration::Registerable`**: Acts as a registration target (students register for the exam)
- **Implements `Roster::Rosterable`**: Manages the list of registered students
- **Implements `Assessment::Assessable`**: Links to an `Assessment::Assessment` for grading

The parent `Lecture` (which implements `Registration::Campaignable`) hosts the registration campaigns. Each exam (Hauptklausur, Nachklausur, etc.) gets its own campaign with that exam as the sole registerable item.

---

## Exam (ActiveRecord Model)

```admonish info "What it represents"
A scheduled exam event with date, location, capacity, and registration deadline.
```

```admonish tip "Think of it as"
The exam equivalent of a Tutorial—it's both a thing students register for and a thing that gets graded.
```

### Key Attributes

| Field | Type | Description |
|-------|------|-------------|
| `lecture_id` | FK | The lecture this exam belongs to (required) |
| `title` | String | Exam title (e.g., "Hauptklausur", "Nachklausur") |
| `date` | DateTime | Scheduled exam date and time |
| `location` | String | Physical location or online meeting link |
| `capacity` | Integer | Maximum number of exam participants (nullable; nil = unlimited) |
| `description` | Text | Additional exam details and instructions |

### Role in the System

**1. As Registerable (Registration Target)**
```ruby
# Creating the exam is the whole step: an after_create hook adds the campaign,
# hosted by the parent lecture, and the single item pointing back at the exam.
exam = lecture.exams.create!(
  title: "Hauptklausur",
  date: 3.weeks.from_now,
  capacity: 200
)

exam.registration_campaign            # draft, first_come_first_served
exam.registration_campaign.registration_deadline  # exam date minus three days
```

Passing `registration_deadline:` to the exam overrides that default, and
`skip_campaigns: true` suppresses the campaign entirely — for exams whose
participants are managed by hand.

**2. As Rosterable (Student Tracking)**
```ruby
# After allocation, students are materialized into the exam roster
exam.roster_user_ids # => [101, 102, 103, ...]
```

**3. As Assessable (Grading Container)**
```ruby
# After the exam, link it to an assessment for grading
assessment = Assessment::Assessment.create!(
  assessable: exam,
  lecture: exam.lecture,
  title: "#{exam.title} Grading"
)
```

### Example Implementation

```ruby
class Exam < ApplicationRecord
  belongs_to :lecture

  include Registration::Registerable
  include Roster::Rosterable
  include Assessment::Assessable

  validates :lecture, presence: true
  validates :title, presence: true
  validates :date, presence: true
  validates :capacity, numericality: { greater_than: 0, allow_nil: true }

  def materialize_allocation!(user_ids:, campaign:)
    replace_roster!(
      user_ids: user_ids,
      source_type: "Registration::Campaign",
      source_id: campaign.id
    )
  end

  def registration_open?
    Time.current < registration_deadline
  end

  def past?
    date < Time.current
  end
end
```

### Database Migration

```ruby
class CreateExams < ActiveRecord::Migration[7.0]
  def change
    create_table :exams do |t|
      t.references :lecture, null: false, foreign_key: true
      t.string :title, null: false
      t.datetime :date, null: false
      t.string :location
      t.integer :capacity, null: false
      t.datetime :registration_deadline
      t.text :description

      t.timestamps
    end

    add_index :exams, [:lecture_id, :date]
  end
end
```

```admonish note "Multiple Choice Exam Extension"
For exams that include multiple choice components requiring legal compliance, see the [Multiple Choice Exams](05c-multiple-choice-exams.md) chapter. That extension adds `has_multiple_choice` and `mc_weight` fields to the schema.
```

---

## Exam Registration Flow

```admonish success "Goal"
Enable students to register for an exam slot while enforcing eligibility and capacity constraints.
```

```admonish info "Eligibility Requirement"
Exam registration typically requires students to meet certain criteria (e.g., earning 50% of homework points). This is handled by the student performance certification system documented in [Student Performance](05-student-performance.md). The eligibility check is enforced via a `Registration::Policy` with `kind: :student_performance`.
```

```admonish warning "The shape of an exam campaign"
An exam campaign holds one item — the exam — and its allocation mode is always
`first_come_first_served`. Preference-based allocation ranks the items on offer,
and here there is only ever the one, so there is nothing to rank.

Both halves are model validations, checked from either side; see
[Uniqueness Constraints](02-registration.md#uniqueness-constraints).

The mode is also what makes eligibility apply at all.
`Registration::FinalizationGuard#check` returns success for a preference-based
campaign *before* it reaches the `ScreeningService`, so an exam campaign in that
mode would admit every registrant, certification or not. That is a consequence
of the rule rather than its reason, but it is the reason the rule is worth
enforcing rather than merely intending.
```

### Setup (Staff Actions)

| Step | Action | Technical Details |
|------|--------|-------------------|
| 1 | Create exam | `lecture.exams.create!(title: "Hauptklausur", date: ..., capacity: 150)` — the campaign (lecture as campaignable) and its single item are created with it |
| 2 | Check the registration deadline | Defaults to three days before the exam. For an exam less than three days out that default is already past, and the campaign cannot be opened until it is corrected |
| 3 | Add eligibility policy | `campaign.registration_policies.create!(kind: :student_performance)` - see [Student Performance](05-student-performance.md) |
| 4 | Create certifications | Teacher creates `StudentPerformance::Certification` records for eligible students (see [Student Performance](05-student-performance.md)) |
| 5 | Pre-flight check | Before opening, verify all active users have certifications (see [End-to-End Workflow Phase 7](06-end-to-end-workflow.md#phase-7-teacher-certification)) |
| 6 | Finalization filtering | On finalize, only allocate students with `Certification.status IN (:passed, :forced_passed)` |
| Preconditions | `lecture.performance_total_points` must be set; certifications must exist for all active lecture users |

### Student Experience

1. Student visits exam registration campaign page
2. System checks eligibility via `Registration::PolicyEngine` (queries `StudentPerformance::Certification.status`)
3. If ineligible, student sees error message explaining why (e.g., "Certification pending" or "Certification failed")
4. If eligible (status IN passed/forced_passed), student sees registration interface
5. Student submits registration
6. Registration is confirmed immediately — exam campaigns are always first-come-first-served
7. After registration closes, `materialize_allocation!` updates exam roster (allocation filtered to only certified students)

---

## Exam Grading Flow

```admonish success "Goal"
Record and process exam grades using the assessment system.
```

### After Exam is Administered

| Step | Action | Technical Details |
|------|--------|-------------------|
| 1 | Create assessment | `Assessment::Assessment.create!(assessable: exam, ...)` |
| 2 | Seed participations | System creates `Assessment::Participation` for each registered student |
| 3 | Define tasks | Staff creates `Assessment::Task` records (e.g., Problem 1, Problem 2) |
| 4 | Enter grades | Tutors record `Assessment::TaskPoint` for each student/task |
| 5 | Apply grade scheme | Staff applies `Assessment::GradeScheme` to convert points to letter grades |

```admonish note "Multiple Choice Exam Extension"
For exams with multiple choice components requiring legal compliance, see the [Multiple Choice Exams](05c-multiple-choice-exams.md) chapter for the two-stage grading process.
```

---

## Usage Scenarios

### Scenario 1: Regular Final Exam
```ruby
exam = lecture.exams.create!(
  title: "Final Exam",
  date: Date.new(2025, 2, 15),
  location: "Main Hall",
  capacity: 200,
  registration_deadline: Date.new(2025, 2, 1)
)

campaign = exam.registration_campaigns.create!(
  title: "Final Exam Registration",
  allocation_mode: :first_come_first_served,
  registration_deadline: exam.registration_deadline
)

campaign.registration_policies.create!(
  kind: :student_performance,
  config: { lecture_id: lecture.id }
)

# Teacher creates certifications for eligible students
lecture.active_users.find_each do |user|
  evaluator = StudentPerformance::Evaluator.new(lecture: lecture, user: user)
  proposal = evaluator.proposal

  StudentPerformance::Certification.create!(
    lecture: lecture,
    user: user,
    status: proposal[:status],  # :passed or :failed
    rule_snapshot: proposal[:rule_snapshot],
    notes: proposal[:notes]
  )
end

# Pre-flight check before opening
campaign.validate_certifications!  # raises if missing certifications
```

### Scenario 2: Multiple Exam Dates (Regular + Retake)

Each exam carries its own campaign; there is no campaign that offers both and
lets students rank them. Sitting the regular exam and the retake are separate
decisions, so registering for one says nothing about the other.

```ruby
regular_exam = lecture.exams.create!(
  title: "Regular Exam",
  date: Date.new(2025, 2, 15),
  capacity: 200
)

retake_exam = lecture.exams.create!(
  title: "Retake Exam",
  date: Date.new(2025, 3, 15),
  capacity: 50
)

# Creating the exam creates its campaign and the single item pointing at it.
regular_exam.registration_campaign  # first_come_first_served, one item
retake_exam.registration_campaign   # a separate campaign, likewise
```

---

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Created
    Created --> RegistrationOpen : registration_deadline not reached
    RegistrationOpen --> RegistrationClosed : deadline passed
    RegistrationClosed --> Administered : exam date reached
    Administered --> Graded : grades entered
    Graded --> [*]
```

---

## Proposed File Structure

```text
app/
└── models/
    └── exam.rb
```
