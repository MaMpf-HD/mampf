require "rails_helper"

RSpec.describe(Lecture) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:student) { create(:confirmed_user) }

  before { Rails.cache.clear }

  def release(medium, level)
    medium.update!(sort: "WorkedExample", released: level, released_at: Time.zone.now)
    medium
  end

  it "offers worked examples released to everybody to a reader" do
    release(create(:lecture_medium, teachable: lecture), "all")

    expect(lecture.worked_example?(student)).to be(true)
  end

  it "offers worked examples released to participants only to participants" do
    release(create(:lecture_medium, teachable: lecture), "subscribers")

    expect(lecture.worked_example?(student)).to be(false)

    participant = create(:confirmed_user)
    participant.bookmark_lecture!(lecture)

    expect(lecture.worked_example?(participant)).to be(true)
    expect(lecture.worked_example?(student)).to be(false)
  end

  it "offers the course's participant media to a participant of another of its lectures" do
    release(create(:course_medium, teachable: lecture.course), "subscribers")
    sibling = create(:lecture, :released_for_all, course: lecture.course)
    student.bookmark_lecture!(sibling)

    expect(lecture.worked_example?(student)).to be(true)
    expect(lecture.worked_example?(create(:confirmed_user))).to be(false)
  end
end
