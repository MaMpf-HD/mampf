require "rails_helper"

RSpec.describe("Lessons", type: :request) do
  let(:student) { create(:confirmed_user) }
  let(:medium) do
    create(:lesson_medium).tap do |lesson_medium|
      lesson_medium.teachable.lecture.update!(released: "all")
      lesson_medium.update!(released: "subscribers", released_at: Time.zone.now,
                            content: "Only for the participants")
    end
  end
  let(:lesson) { medium.teachable }

  before { sign_in student }

  it "leaves a participants-only medium out of the outline for a mere reader" do
    get lesson_path(lesson)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Only for the participants")
  end

  it "shows it to a student who takes part in the lecture" do
    student.bookmark_lecture!(lesson.lecture)

    get lesson_path(lesson)

    expect(response.body).to include("Only for the participants")
  end
end
