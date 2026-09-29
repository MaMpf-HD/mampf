require "rails_helper"

RSpec.describe(Demo::PerformanceSetupSupport, type: :model) do
  # A second run meets the values the first one entered; those are the demo's
  # to throw away, where a lecturer's would lock the achievement.
  it "resets its own achievements although values were entered on them" do
    lecture = create(:lecture)
    student = create(:confirmed_user)
    create(:lecture_membership, lecture: lecture, user: student)
    title = described_class::DEMO_ACHIEVEMENT_ATTRIBUTES.first[:title]
    achievement = create(:achievement, :boolean, lecture: lecture, title: title)
    achievement.assessment.assessment_participations.find_by!(user: student)
               .update!(grade_text: Achievement::PASSED)

    support = Object.new.extend(described_class)
    expect { support.send(:reset_demo_performance!, lecture) }
      .to change(Achievement, :count).by(-1)
  end
end
