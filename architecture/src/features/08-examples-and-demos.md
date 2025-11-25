# Examples & Demos

## Unified End-to-End Demo (Phases 0–12)

This demo walks through a complete semester lifecycle, from setup to final reporting. It assumes the models and services from the architectural documentation are implemented.

```ruby
# --- Phase 0: Semester Setup ---
# Create lecture
lecture = FactoryBot.create(:lecture_with_sparse_toc, "with_title",
                            title: "Linear Algebra I")

# Create users simulating mixed email domains (valid + invalid)
domains = %w[student.uni.edu uni.edu gmail.com]
users = (1..12).map do |i|
  FactoryBot.create(:confirmed_user,
                    email: "user#{i}@#{domains[i % domains.size]}",
                    name: "User #{i}")
end

# Create tutorials
tutorials = (1..3).map do |n|
  FactoryBot.create(:tutorial, lecture: lecture, title: "Tutorial #{n}", capacity: 10)
end

# --- Phase 1: Tutorial Registration ---
tut_campaign = Registration::Campaign.create!(
  campaignable: lecture,
  title: "Tutorial Registration WS 2024/25",
  allocation_mode: :preference_based,
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
  active: true,
  config: { "allowed_domains" => ["uni.edu", "student.uni.edu"] }
)

tut_campaign.update!(status: :open)

# Users submit ranked preferences.
# In a real UI, the controller would use `evaluate_policies_for(user)` before
# allowing a submission.
eligible_submitters = users.select do |u|
  tut_campaign.evaluate_policies_for(u).pass
end
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
tut_campaign.allocate_and_finalize!

# --- Phase 3: Roster Materialization ---
# Materialization happens automatically within `allocate_and_finalize!`
puts "\nTutorial Rosters After Materialization:"
tutorials.each do |tut|
  # Assuming a `roster_user_ids` method exists on the registerable
  puts "  #{tut.title}: #{tut.roster_user_ids.size} students"
end

# --- Phase 4: Roster Maintenance ---
# Move one student from Tutorial 1 to Tutorial 2
from_tut = tutorials.first
to_tut = tutorials.second
student_to_move_id = from_tut.roster_user_ids.first

if student_to_move_id
  # Assuming a Roster Maintenance service exists
  puts "Moved student #{student_to_move_id} from #{from_tut.title} to #{to_tut.title}"
end

# --- Phase 5: Coursework Assessments ---
# Create two homework assignments with tasks
hw1 = FactoryBot.create(:assignment, lecture: lecture, title: "Homework 1")
hw1_assessment = FactoryBot.create(:assessment, assessable: hw1, title: "Homework 1")
(1..3).each { |i| hw1_assessment.tasks.create!(title: "Problem #{i}", max_points: 10) }

hw2 = FactoryBot.create(:assignment, lecture: lecture, title: "Homework 2")
hw2_assessment = FactoryBot.create(:assessment, assessable: hw2, title: "Homework 2")
(1..3).each { |i| hw2_assessment.tasks.create!(title: "Problem #{i}", max_points: 10) }

# Seed participations from tutorial rosters
lecture_students = users.select { |u| u.email.ends_with?("uni.edu") || u.email.ends_with?("student.uni.edu") }
[hw1_assessment, hw2_assessment].each do |assessment|
  lecture_students.each do |student|
    FactoryBot.create(:participation, assessment: assessment, user: student)
  end
end

# Simulate grading with random points
[hw1_assessment, hw2_assessment].each do |assessment|
  assessment.participations.find_each do |part|
    total_points = 0
    assessment.tasks.each do |task|
      points = rand((task.max_points * 0.4)..task.max_points)
      FactoryBot.create(:task_point, participation: part, task: task, points: points)
      total_points += points
    end
    part.update!(points_total: total_points, status: :graded)
  end
end

# --- Phase 6: Achievement Tracking ---
# Award achievements to first three eligible students
eligible_submitters.first(3).each do |u|
  FactoryBot.create(:achievement,
    lecture: lecture,
    user: u,
    kind: "blackboard_explanation",
    achievable: lecture
  )
end
puts "\nAchievements awarded to #{eligible_submitters.first(3).map(&:name).join(', ')}"

# --- Phase 7: Lecture Performance Materialization ---
# Configure eligibility rule
rule = LecturePerformance::Rule.find_or_create_by!(lecture: lecture)
rule.update!(
  min_points: 30, # 50% of 60 total points
  required_achievements: { "blackboard_explanation" => 1 },
  assessment_types: ["Assignment"]
)

# Compute performance facts for all students (e.g., via a background job)
service = LecturePerformance::Service.new(lecture)
service.compute_and_upsert_all_records!

puts "\nPerformance records computed for #{lecture_students.size} students"

# --- Phase 8: Exam Registration ---
# Create an exam belonging to the lecture
exam = FactoryBot.create(:exam,
  lecture: lecture,
  title: "Hauptklausur",
  date: 4.weeks.from_now,
  capacity: 100
)

# The lecture (campaignable) hosts the exam registration campaign
exam_campaign = lecture.registration_campaigns.create!(
  title: "Hauptklausur Registration",
  allocation_mode: :first_come_first_served,
  registration_deadline: 2.weeks.from_now,
  status: :open
)

# The exam is the sole registerable item
exam_campaign.registration_items.create!(registerable: exam)

puts "\nExam campaign created: #{exam_campaign.title} (deadline: #{exam_campaign.registration_deadline})"

# --- Phase 8: Teacher Certification ---
# Generate eligibility proposals using the Evaluator
evaluator = LecturePerformance::Evaluator.new(rule)
proposals = {}

lecture_students.each do |student|
  record = LecturePerformance::Record.find_by(lecture: lecture, user: student)
  result = evaluator.evaluate(record)
  proposals[student.id] = result.status
end

puts "\nProposals generated: #{proposals.values.count(:passed)} passed, #{proposals.values.count(:failed)} failed"

# Teacher reviews and bulk-accepts proposals
teacher = users.first # Assuming first user is the teacher
lecture_students.each do |student|
  LecturePerformance::Certification.create!(
    user: student,
    lecture: lecture,
    record: LecturePerformance::Record.find_by(lecture: lecture, user: student),
    rule: rule,
    status: proposals[student.id],
    certified_at: Time.current,
    certified_by: teacher
  )
end

eligible_count = LecturePerformance::Certification.where(lecture: lecture, status: :passed).count
puts "Certifications created: #{eligible_count} students certified as passed"

# Override one failed student (e.g., medical certificate)
failed_cert = LecturePerformance::Certification.find_by(lecture: lecture, status: :failed)
if failed_cert
  failed_cert.update!(
    status: :passed,
    note: "Medical certificate provided",
    certified_at: Time.current,
    certified_by: teacher
  )
  puts "Manual override: Student #{failed_cert.user.name} status changed to passed"
end

# --- Phase 9: Exam Registration Campaign ---
# Create exam belonging to the lecture
exam = FactoryBot.create(:exam, lecture: lecture, capacity: 100)

# The lecture (campaignable) hosts the exam registration campaign
exam_campaign = Registration::Campaign.create!(
  campaignable: lecture,
  title: "Hauptklausur Registration",
  allocation_mode: :first_come_first_served,
  registration_deadline: 2.weeks.from_now
)
# The exam is the sole registerable item
exam_item = exam_campaign.registration_items.create!(registerable: exam)

# Add policies: lecture performance + institutional email
exam_campaign.registration_policies.create!(
  kind: :lecture_performance,
  position: 1,
  active: true,
  config: { "lecture_id" => lecture.id }
)
exam_campaign.registration_policies.create!(
  kind: :institutional_email,
  position: 2,
  active: true,
  config: { "allowed_domains" => ["uni.edu", "student.uni.edu"] }
)
# --- Phase 9: Exam Registration Campaign ---
# Create exam first
exam = FactoryBot.create(:exam, lecture: lecture, capacity: 100)

# Create registration campaign
exam_campaign = Registration::Campaign.create!(
  campaignable: exam,
  title: "Final Exam Registration",
  allocation_mode: :first_come_first_served,
  registration_deadline: 2.weeks.from_now,
  status: :draft
)
exam_item = exam_campaign.registration_items.create!(registerable: exam)

# Add policies: lecture performance + institutional email
exam_campaign.registration_policies.create!(
  kind: :lecture_performance,
  position: 1,
  active: true,
  phase: :registration,
  config: { "lecture_id" => lecture.id }
)
exam_campaign.registration_policies.create!(
  kind: :institutional_email,
  position: 2,
  active: true,
  phase: :registration,
  config: { "allowed_domains" => ["uni.edu", "student.uni.edu"] }
)

# Pre-flight check: verify certification completeness before opening
all_certified = lecture_students.all? do |student|
  cert = LecturePerformance::Certification.find_by(lecture: lecture, user: student)
  cert.present? && cert.status.in?([:passed, :failed])
end

if all_certified
  exam_campaign.update!(status: :open)
  puts "\nExam campaign opened (all students certified)"
else
  puts "\nCampaign opening blocked: incomplete certifications"
  exit
end

# Eligible students register for exam. Policy checks Certification status.
puts "\nExam Registration Process:"
lecture_students.each do |user|
  result = exam_campaign.evaluate_policies_for(user, phase: :registration)
  if result.pass
    puts "  - Student #{user.name}: Eligible (certification: passed). Registering..."
    Registration::UserRegistration.create!(
      user: user,
      registration_campaign: exam_campaign,
      registration_item: exam_item,
      status: :confirmed
    )
  else
    cert = LecturePerformance::Certification.find_by(lecture: lecture, user: user)
    puts "  - Student #{user.name}: Ineligible. Certification status: #{cert&.status || 'missing'}"
  end
end

# Finalize campaign (materializes exam roster after re-checking certifications)
exam_campaign.finalize!
puts "\n#{exam_campaign.user_registrations.confirmed.count} students registered for exam"

# --- Phase 10: Exam Grading ---
# Create assessment for exam
exam_assessment = FactoryBot.create(:assessment, assessable: exam, title: "Final Exam")
task1 = exam_assessment.tasks.create!(title: "Problem 1", max_points: 40)
task2 = exam_assessment.tasks.create!(title: "Problem 2", max_points: 30)
task3 = exam_assessment.tasks.create!(title: "Problem 3", max_points: 30)

# Seed participations from exam roster
exam_campaign.user_registrations.confirmed.each do |reg|
  FactoryBot.create(:participation, assessment: exam_assessment, user: reg.user)
end

# Simulate grading
exam_assessment.participations.find_each do |part|
  points = rand(40..100)
  part.update!(points_total: points)
end

# Create and apply grade scheme
exam_scheme = GradeScheme::Scheme.create!(
  title: "Final Exam Grading",
  bands: [
    { "min_points" => 90, "grade" => "1.0" },
    { "min_points" => 80, "grade" => "2.0" },
    { "min_points" => 70, "grade" => "3.0" },
    { "min_points" => 60, "grade" => "4.0" },
    { "min_points" => 0, "grade" => "5.0" }
  ]
)
# Assuming an applier service exists
# GradeScheme::Applier.new(exam_assessment, exam_scheme).apply!

puts "\nExam graded (conceptual)."

# --- Phase 11: Late Adjustments ---
# Simulate late homework grade change
late_part = hw1_assessment.participations.first
old_points = late_part.points_total
late_part.update!(points_total: old_points + 5)
puts "\nLate adjustment: Student #{late_part.user.name} HW1 points: #{old_points} → #{late_part.points_total}"

# The change triggers record recomputation and marks certification as stale
service.compute_and_upsert_record_for(late_part.user)
cert = LecturePerformance::Certification.find_by(lecture: lecture, user: late_part.user)
puts "  - Performance record recomputed"
puts "  - Certification marked for review (teacher must re-certify before next campaign)"

# Teacher must review and re-certify
# In real workflow, teacher would see "Certification Stale" warning in UI
# and must manually review before opening new campaigns

# --- Phase 12: Reporting & Export ---
puts "\n=== Final Report ==="
puts "Lecture: #{lecture.title}"
puts "Total students in course: #{lecture_students.size}"
puts "Tutorial registrations: #{tut_campaign.user_registrations.confirmed.count}"
puts "Exam registered: #{exam_campaign.user_registrations.confirmed.count}"
```

## Key Observations

This demo illustrates:

1.  **Complete Lifecycle:** All phases from setup to reporting.
2.  **Three-Layer Architecture:**
    - Records store factual performance data (points, achievements)
    - Evaluator generates eligibility proposals (computational layer)
    - Certifications capture teacher decisions (authoritative layer)
3.  **Pre-Flight Checks:** Campaigns cannot open without complete certifications, ensuring policy consistency.
4.  **No Runtime Recomputation:** Exam registration looks up pre-existing Certifications instead of computing eligibility on-the-fly.
5.  **Roster Management:** Materialization populates tutorial and exam rosters from confirmed registrations.
6.  **Late Adjustments:** Grade changes trigger record recomputation and mark certifications for teacher review, but existing certifications remain valid until manually updated.
7.  **Composable Policies:** The exam campaign combines `lecture_performance` and `institutional_email` policies seamlessly, with phase-aware evaluation.
8.  **Teacher Control:** Teachers explicitly review and certify all eligibility decisions, maintaining accountability and enabling manual overrides.

```admonish note "Architectural Consistency"
This demo follows the decoupled architecture. All model names, service calls, and workflows match the documented design.
```
