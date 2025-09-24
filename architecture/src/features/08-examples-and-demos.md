# Examples & Demos

## Unified End-to-End Demo (Phases 0–13)
This demo assumes the models and services from the architectural docs are implemented.

```ruby
# --- Phase 0: Domain & Roster Foundations ---
lecture = Lecture.first
l.update(capacity: 500)

# Create some users (simulate mixed valid + invalid email domains) -- this code is for demonstration of the workflow
# only, not working like this ion the actual app
domains = %w[student.uni.edu uni.edu gmail.com]
users = (1..12).map do |i|
    User.find_or_create_by!(email: "user#{i}@#{domains[i % domains.size]}") do |u|
        u.name = "User #{i}"
    end
end

# --- Phase 1: Tutorial Registration Campaign (Preference-Based) ---
tutorials = (1..3).map do |n|
    Tutorial.find_or_create_by!(lecture: lecture, title: "Tutorial #{n}") do |t|
        t.capacity = 5
    end
end

tut_campaign = lecture.create_campaign!(
    tutorials,
    title: "Tutorial Registration – WS",
    mode: :preference_based,
    deadline: 10.minutes.from_now
)

# Institutional email policy (allow only *.uni.edu & student.uni.edu)
tut_campaign.registration_policies.create!(
    kind: :institutional_email,
    position: 1,
    config: { allowed_domains: ["uni.edu", "student.uni.edu"] }
)

tut_campaign.update!(status: :open)

# Each eligible user submits ranked preferences (skip gmail users; they will fail policy anyway)
eligible_submitters = users.reject { |u| u.email.end_with?("gmail.com") }
ri_map = tut_campaign.registration_items.index_by(&:registerable_id)

eligible_submitters.each_with_index do |user, idx|
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

# --- Phase 2: Run Preference-Based Allocation ---
# Fast-forward deadline
tut_campaign.update!(registration_deadline: Time.current - 1.second)
tut_campaign.run_assignment!   # sets confirmed/rejected + finalize! (materialization)

# --- Phase 3: Allocation Materialization (Tutorial Rosters) ---
# (Done implicitly by finalize! → AllocationMaterializer → tutorial.materialize_allocation!)
puts "\nTutorial Rosters After Materialization:"
tutorials.each do |t|
    puts "  #{t.title}: #{t.roster_user_ids.size} users"
end

# --- Phase 4: Post-Allocation Administration ---
# Move one student from Tutorial 1 to Tutorial 2
svc = RegisterableRosterService.new(actor: User.first)
from_tut = tutorials.first
to_tut   = tutorials.second
mover_id = from_tut.roster_user_ids.first
if mover_id
    svc.move_user!(user_id: mover_id, from: from_tut, to: to_tut, reason: "Load balancing")
end

# --- Phase 5: Coursework Assessments & Grading ---
# Create two homework assignments with tasks and seed participations from current tutorial rosters
def create_hw(lecture:, title:, max_points:)
    assignment = Assignment.find_or_create_by!(lecture: lecture, title: title) do |a|
        a.capacity = 1000
    end
    assignment.ensure_pointbook!(title: title, requires_submission: true)
    assignment.seed_participations_from_roster! # relies on tutorials populating lecture.students if implemented, else custom aggregate
    assessment = assignment.assessment
    (1..3).each do |i|
        assessment.tasks.find_or_create_by!(title: "Problem #{i}") do |t|
            t.max_points = max_points / 3.0
        end
    end
    assignment
end

hw1 = create_hw(lecture: lecture, title: "HW1", max_points: 30)
hw2 = create_hw(lecture: lecture, title: "HW2", max_points: 30)

# Simulate grading: assign random points per task per participant
[hw1, hw2].each do |assign|
    assessment = assign.assessment
    tasks = assessment.tasks.order(:id).to_a
    assessment.assessment_participations.find_each do |part|
        tasks.each do |task|
            tp = TaskPoint.find_or_initialize_by(assessment_participation: part, task: task)
            tp.points = rand( (task.max_points * 0.4)..task.max_points )
            tp.state  = :published
            tp.save!
        end
        part.recompute_points_total!
        part.update!(status: :graded, published: true)
    end
end

# --- Phase 6: Achievements ---
# Give first three users a blackboard explanation credit
eligible_submitters.first(3).each do |u|
    LectureAchievement.create!(lecture: lecture, user: u, kind: "blackboard_explanation", count: 1)
end

# --- Phase 7: Exam Eligibility Computation ---
policy = lecture.exam_eligibility_policy || lecture.build_exam_eligibility_policy
policy.update!(
    min_percentage: 50,
    required_achievement_kind: "blackboard_explanation",
    required_achievement_count: 1,
    included_assessment_types: "assignment",
    include_archived: false
)

ExamEligibilityService.new.compute!(lecture: lecture)

ineligible = ExamEligibilityRecord.where(lecture: lecture, computed_status: :ineligible).limit(2)
# Override one borderline candidate (if any)
if (rec = ineligible.first)
    rec.update!(
        override_status: :override_eligible,
        override_reason: "Medical certificate",
        override_by: User.first,
        override_at: Time.current
    )
end

# --- Phase 8: Exam Registration (Policy-Gated) ---
exam_sessions = [Exam.find_or_create_by!(lecture: lecture, title: "Final Exam Session A") do |e|
    e.capacity = 100
end]

exam_campaign = lecture.create_campaign!(
    exam_sessions,
    title: "Final Exam Registration",
    mode: :first_come_first_serve,
    deadline: 2.days.from_now
)

# Policies: exam eligibility + institutional email
exam_campaign.registration_policies.create!(
    kind: :exam_eligibility, position: 1, config: { lecture_id: lecture.id }
)
exam_campaign.registration_policies.create!(
    kind: :institutional_email, position: 2, config: { allowed_domains: ["uni.edu", "student.uni.edu"] }
)

exam_campaign.update!(status: :open)

exam_item = exam_campaign.registration_items.first

eligible_submitters.each do |user|
    next unless exam_campaign.eligible_user?(user)
    Registration::UserRegistration.create!(
        user: user,
        registration_campaign: exam_campaign,
        registration_item: exam_item,
        status: :confirmed
    )
end
exam_campaign.finalize!

# --- Phase 9: Exam Assessment Creation & Grading ---
exam = exam_sessions.first
exam.ensure_pointbook!(title: "Final Exam", requires_submission: false)
exam.seed_participations_from_roster!  # seeds from materialized exam roster (confirmed exam registrants)
```
