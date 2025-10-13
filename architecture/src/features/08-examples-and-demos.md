# Examples & Demos

## Unified End-to-End Demo (Phases 0–11)

This demo walks through a complete semester lifecycle, from setup to final reporting. It assumes the models and services from the architectural documentation are implemented.

```ruby
# --- Phase 0: Semester Setup ---
# Create lecture and configure capacity
lecture = Lecture.find_or_create_by!(title: "Linear Algebra I", semester: "WS 2024/25") do |l|
  l.capacity = 500
end

# Create users simulating mixed email domains (valid + invalid)
domains = %w[student.uni.edu uni.edu gmail.com]
users = (1..12).map do |i|
  User.find_or_create_by!(email: "user#{i}@#{domains[i % domains.size]}") do |u|
    u.name = "User #{i}"
  end
end

# Create tutorials
tutorials = (1..3).map do |n|
  Tutorial.find_or_create_by!(lecture: lecture, title: "Tutorial #{n}") do |t|
    t.capacity = 5
  end
end

# --- Phase 1: Tutorial Registration ---
tut_campaign = Registration::Campaign.create!(
  campaignable: lecture,
  title: "Tutorial Registration WS 2024/25",
  mode: :preference_based,
  registration_deadline: 10.days.from_now
)

# Create registration items for each tutorial
tutorials.each do |tut|
  tut_campaign.registration_items.create!(registerable: tut)
end

# Add institutional email policy
tut_campaign.registration_policies.create!(
  kind: :institutional_email,
  position: 1,
  config: { allowed_domains: ["uni.edu", "student.uni.edu"] }
)

tut_campaign.update!(status: :open)

# Users submit ranked preferences (gmail users will fail policy)
eligible_submitters = users.reject { |u| u.email.end?("gmail.com") }
ri_map = tut_campaign.registration_items.index_by(&:registerable_id)

eligible_submitters.each do |user|
  shuffled = tutorials.shuffle
  shuffled.each_with_index do |tut, rank|
    Registration::UserRegistration.create!(
      user: user,
      registration_campaign: tut_campaign,
      registration_item: ri_map[tut.id],
      status: :pending,
      preference_rank: rank + 1
    )
  end
end

# --- Phase 2: Tutorial Allocation ---
# Close registration and run allocation algorithm
tut_campaign.update!(registration_deadline: Time.current - 1.second)
Registration::AllocationService.new(tut_campaign).run!

# --- Phase 3: Roster Materialization ---
# Materialization happens automatically after allocation
puts "\nTutorial Rosters After Materialization:"
tutorials.each do |tut|
  roster = tut.roster
  puts "  #{tut.title}: #{roster.user_ids.size} students"
end

# --- Phase 4: Roster Maintenance ---
# Move one student from Tutorial 1 to Tutorial 2
from_tut = tutorials.first
to_tut = tutorials.second
student_to_move = from_tut.roster.user_ids.first

if student_to_move
  Roster::MaintenanceService.new(actor: User.first).move_user!(
    user_id: student_to_move,
    from: from_tut,
    to: to_tut,
    reason: "Load balancing"
  )
  puts "Moved student #{student_to_move} from #{from_tut.title} to #{to_tut.title}"
end

# --- Phase 5: Coursework Assessments ---
# Create two homework assignments with tasks
hw1 = Assignment.create!(lecture: lecture, title: "Homework 1")
hw1_assessment = Assessment::Assessment.create!(
  assessable: hw1,
  title: "Homework 1",
  requires_submission: true
)

(1..3).each do |i|
  hw1_assessment.tasks.create!(title: "Problem #{i}", max_points: 10)
end

# Seed participations from tutorial rosters
lecture_students = tutorials.flat_map { |t| t.roster.user_ids }.uniq
lecture_students.each do |user_id|
  Assessment::Participation.create!(
    assessment: hw1_assessment,
    user_id: user_id
  )
end

hw2 = Assignment.create!(lecture: lecture, title: "Homework 2")
hw2_assessment = Assessment::Assessment.create!(
  assessable: hw2,
  title: "Homework 2",
  requires_submission: true
)

(1..3).each do |i|
  hw2_assessment.tasks.create!(title: "Problem #{i}", max_points: 10)
end

lecture_students.each do |user_id|
  Assessment::Participation.create!(
    assessment: hw2_assessment,
    user_id: user_id
  )
end

# Simulate grading with random points
[hw1_assessment, hw2_assessment].each do |assessment|
  tasks = assessment.tasks.order(:id).to_a
  assessment.participations.find_each do |part|
    tasks.each do |task|
      Assessment::TaskPoint.create!(
        participation: part,
        task: task,
        points: rand((task.max_points * 0.4)..task.max_points),
        state: :published
      )
    end
    part.recompute_total_points!
    part.update!(status: :graded)
  end
end

# --- Phase 6: Achievement Tracking ---
# Award achievements to first three eligible students
eligible_submitters.first(3).each do |u|
  Achievement::Record.create!(
    lecture: lecture,
    user: u,
    kind: "blackboard_explanation",
    count: 1
  )
end

puts "\nAchievements awarded to #{eligible_submitters.first(3).map(&:name).join(', ')}"

# --- Phase 7: Exam Eligibility Computation ---
# Configure eligibility policy
policy = ExamEligibility::Policy.find_or_create_by!(lecture: lecture)
policy.update!(
  min_percentage: 50.0,
  required_achievement_kind: "blackboard_explanation",
  required_achievement_count: 1,
  included_assessment_types: ["assignment"],
  include_archived: false
)

# Compute eligibility for all students
ExamEligibility::ComputationService.new(lecture: lecture).compute!

# Check results
eligible_count = ExamEligibility::Record.where(
  lecture: lecture,
  final_status: :eligible
).count
puts "\n#{eligible_count} students are eligible for the exam"

# Override one ineligible student (e.g., medical certificate)
ineligible_record = ExamEligibility::Record.where(
  lecture: lecture,
  computed_status: :ineligible
).first

if ineligible_record
  ineligible_record.update!(
    override_status: :override_eligible,
    override_reason: "Medical certificate provided",
    override_by: User.first,
    override_at: Time.current
  )
  puts "Overridden eligibility for student #{ineligible_record.user_id}"
end

# --- Phase 8: Exam Registration Campaign ---
# Create exam first (before registration opens)
exam = Exam.create!(
  lecture: lecture,
  title: "Final Exam",
  exam_date: 3.months.from_now,
  location: "Main Hall",
  capacity: 100
)

# Create registration campaign
exam_campaign = Registration::Campaign.create!(
  campaignable: lecture,
  title: "Final Exam Registration",
  mode: :first_come_first_serve,
  registration_deadline: 2.weeks.from_now
)

# Create registration item for the exam
exam_item = exam_campaign.registration_items.create!(registerable: exam)

# Add policies: exam eligibility + institutional email
exam_campaign.registration_policies.create!(
  kind: :exam_eligibility,
  position: 1,
  config: { lecture_id: lecture.id }
)
exam_campaign.registration_policies.create!(
  kind: :institutional_email,
  position: 2,
  config: { allowed_domains: ["uni.edu", "student.uni.edu"] }
)

exam_campaign.update!(status: :open)

# Eligible students register for exam
eligible_submitters.each do |user|
  next unless exam_campaign.policies_satisfied_for?(user)

  Registration::UserRegistration.create!(
    user: user,
    registration_campaign: exam_campaign,
    registration_item: exam_item,
    status: :confirmed
  )
end

# Finalize campaign (materializes exam roster)
exam_campaign.finalize!
puts "\n#{exam.roster.user_ids.size} students registered for exam"

# --- Phase 9: Exam Grading ---
# Create assessment for exam
exam_assessment = Assessment::Assessment.create!(
  assessable: exam,
  title: "Final Exam",
  requires_submission: false
)

# Create tasks for different exam problems
task1 = exam_assessment.tasks.create!(
  title: "Problem 1: Linear Systems",
  max_points: 40
)

task2 = exam_assessment.tasks.create!(
  title: "Problem 2: Vector Spaces",
  max_points: 30
)

task3 = exam_assessment.tasks.create!(
  title: "Problem 3: Eigenvalues",
  max_points: 30
)

# Seed participations from exam roster
exam.roster.user_ids.each do |user_id|
  Assessment::Participation.create!(
    assessment: exam_assessment,
    user_id: user_id
  )
end

# Simulate grading
exam_assessment.participations.find_each do |part|
  [task1, task2, task3].each do |task|
    Assessment::TaskPoint.create!(
      participation: part,
      task: task,
      points: rand((task.max_points * 0.4)..task.max_points),
      state: :published
    )
  end
  part.recompute_total_points!
end

# Create and apply grade scheme
exam_scheme = GradeScheme::Scheme.create!(
  title: "Final Exam Grading",
  bands: [
    { min_percentage: 0.90, grade: 1.0 },
    { min_percentage: 0.80, grade: 2.0 },
    { min_percentage: 0.70, grade: 3.0 },
    { min_percentage: 0.60, grade: 4.0 },
    { min_percentage: 0.00, grade: 5.0 }
  ]
)

GradeScheme::Applier.new(exam_assessment, exam_scheme).apply!

puts "\nExam graded:"
exam_assessment.participations.find_each do |part|
  status = part.passed? ? "PASSED" : "FAILED"
  puts "  Student #{part.user_id}: #{part.total_points}/100 points → Grade #{part.grade_value} (#{status})"
end# --- Phase 10: Late Adjustments ---
# Simulate late homework grade change
late_hw_part = hw1_assessment.participations.first
old_points = late_hw_part.total_points

# Update one task point
task_to_update = hw1_assessment.tasks.first
late_hw_part.task_points.find_by(task: task_to_update).update!(points: 10)
late_hw_part.recompute_total_points!

puts "\nLate adjustment: Student #{late_hw_part.user_id} HW1 points: #{old_points} → #{late_hw_part.total_points}"

# Recompute eligibility if needed
if late_hw_part.total_points > old_points
  ExamEligibility::ComputationService.new(
    lecture: lecture,
    user_ids: [late_hw_part.user_id]
  ).compute!
  puts "Recomputed eligibility for student #{late_hw_part.user_id}"
end

# --- Phase 11: Reporting & Export ---
# Generate eligibility report
eligible_records = ExamEligibility::Record.where(
  lecture: lecture,
  final_status: :eligible
)

puts "\n=== Final Report ==="
puts "Lecture: #{lecture.title}"
puts "Total students: #{lecture_students.size}"
puts "Tutorial registrations: #{tut_campaign.user_registrations.confirmed.count}"
puts "Exam eligible: #{eligible_records.count}"
puts "Exam registered: #{exam.roster.user_ids.size}"
puts "Exam passed: #{exam_assessment.participations.where(passed: true).count}"
puts "Exam failed: #{exam_assessment.participations.where(passed: false).count}"

# Example: Export grades to CSV (conceptual)
puts "\nGrade distribution:"
exam_assessment.participations.group(:grade_value).count.sort.each do |grade, count|
  puts "  Grade #{grade}: #{count} students"
end
```

## Key Observations

This demo illustrates:

1. **Complete Lifecycle:** All 12 phases from setup to reporting
2. **Policy Enforcement:** Email domain validation and exam eligibility checks
3. **Roster Management:** Materialization and maintenance across tutorial groups and exams
4. **Late Adjustments:** Grade changes with automatic eligibility recomputation
5. **Achievement System:** Tracking and using achievements for eligibility
6. **Standard Grading:** Simple point-to-grade conversion using grade schemes

```admonish note "Architectural Consistency"
This demo follows the architecture defined in Chapters 1-5a. All model names, service calls, and workflows match the documented design.
```

```admonish info "Multiple Choice Exams"
This example uses a standard exam for simplicity. For exams with multiple choice components that require German legal compliance (Gleitklausel), see [Multiple Choice Exams](05c-multiple-choice-exams.md).
```
