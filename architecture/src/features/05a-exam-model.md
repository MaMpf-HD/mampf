# Exam Model

```admonish question "What is an 'Exam'?"
An exam is a scheduled assessment event where students demonstrate their knowledge under controlled conditions.

- **Common Examples:** "Final Exam Linear Algebra", "Midterm Calculus", "Retake Exam Analysis"
- **In this context:** A new domain model that acts as a registration target (students sign up for exam slots), manages rosters (tracking who is registered), and links to the assessment system for grading. Exams belong to a lecture.
```

## Problem Overview
MaMpf needs a formal representation of exams that can:
- Act as a registration target with capacity limits and eligibility checks (see [Lecture Performance](05-lecture-performance.md))
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
# The parent lecture hosts the campaign
lecture = Lecture.find(123)
campaign = lecture.registration_campaigns.create!(
  title: "Hauptklausur Registration",
  allocation_mode: :first_come_first_served,
  registration_deadline: 2.weeks.from_now
)

# The exam is the sole registerable item
exam = lecture.exams.create!(
  title: "Hauptklausur",
  date: 3.weeks.from_now,
  capacity: 200
)
campaign.registration_items.create!(registerable: exam)
```

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
Exam registration typically requires students to meet certain criteria (e.g., earning 50% of homework points). This is handled by the lecture performance certification system documented in [Lecture Performance](05-lecture-performance.md). The eligibility check is enforced via a `Registration::Policy` with `kind: :lecture_performance`.
```

### Setup (Staff Actions)

| Step | Action | Technical Details |
|------|--------|-------------------|
| 1 | Create exam | `lecture.exams.create!(title: "Hauptklausur", date: ..., capacity: 150)` |
| 2 | Create campaign | `lecture.registration_campaigns.create!(...)` (lecture as campaignable) |
| 3 | Create item | `campaign.registration_items.create!(registerable: exam)` |
| 4 | Add eligibility policy | `campaign.registration_policies.create!(kind: :lecture_performance)` - see [Lecture Performance](05-lecture-performance.md) |
| 5 | Create certifications | Teacher creates `LecturePerformance::Certification` records for eligible students (see [Lecture Performance](05-lecture-performance.md)) |
| 6 | Pre-flight check | Before opening, verify all active users have certifications (see [End-to-End Workflow Phase 7](06-end-to-end-workflow.md#phase-7-teacher-certification)) |
| 7 | Finalization filtering | On finalize, only allocate students with `Certification.status IN (:passed, :forced_passed)` |
| Preconditions | `lecture.performance_total_points` must be set; certifications must exist for all active lecture users |

### Student Experience

1. Student views open exam registration campaigns
2. System checks eligibility via `Registration::PolicyEngine` (queries `LecturePerformance::Certification.status`)
3. If eligible (status IN passed/forced_passed), student submits registration
4. Registration is confirmed immediately (FCFS) or after deadline (preference-based, if multiple exam dates)
5. After registration closes, `materialize_allocation!` updates exam roster (allocation filtered to only certified students)

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
| 5 | Apply grade scheme | Staff applies `GradeScheme::Scheme` to convert points to letter grades |

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
  kind: :lecture_performance,
  config: { lecture_id: lecture.id }
)

# Teacher creates certifications for eligible students
lecture.active_users.find_each do |user|
  evaluator = LecturePerformance::Evaluator.new(lecture: lecture, user: user)
  proposal = evaluator.proposal

  LecturePerformance::Certification.create!(
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

campaign = lecture.registration_campaigns.create!(
  title: "Exam Date Selection",
  allocation_mode: :preference_based
)

campaign.registration_items.create!(registerable: regular_exam)
campaign.registration_items.create!(registerable: retake_exam)
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
