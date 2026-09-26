require "rails_helper"

# Each way into a lecture's audience on its own: the records are made
# directly, so no roster service adds a bookmark or a lecture membership on
# the side, and both directions of LectureAudience are asked each time.
RSpec.describe(LectureAudience) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:student) { create(:confirmed_user) }

  def in_audience?
    forward = described_class.users(lecture.id).exists?(id: student.id)
    backward = described_class.lectures_of(student).exists?(id: lecture.id)
    expect(forward).to eq(backward)
    forward
  end

  def expect_no_other_tie
    expect(LectureBookmark.exists?(user: student)).to be(false)
    expect(LectureMembership.exists?(user: student)).to be(false)
  end

  def register(status, campaign_status)
    campaign = create(:registration_campaign, campaign_status, :with_items,
                      campaignable: lecture)
    create(:registration_user_registration, status,
           user: student, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)
  end

  it "leaves out a student who only reads the open lecture" do
    student

    expect(in_audience?).to be(false)
  end

  it "takes in a bookmark" do
    create(:lecture_bookmark, user: student, lecture: lecture)

    expect(in_audience?).to be(true)
  end

  it "takes in a lecture membership" do
    create(:lecture_membership, user: student, lecture: lecture)

    expect(in_audience?).to be(true)
  end

  it "takes in a seat in a lecture cohort that does not reach the lecture roster" do
    cohort = create(:cohort, context: lecture, propagate_to_lecture: false)
    create(:cohort_membership, user: student, cohort: cohort)

    expect_no_other_tie
    expect(in_audience?).to be(true)
  end

  it "takes in a talk" do
    seminar = create(:seminar, :released_for_all)
    create(:speaker_talk_join, speaker: student, talk: create(:talk, lecture: seminar))

    expect(described_class.users(seminar.id).exists?(id: student.id)).to be(true)
    expect(described_class.lectures_of(student).exists?(id: seminar.id)).to be(true)
  end

  it "takes in an active exam entry, but not an excluded one" do
    entry = create(:exam_roster_entry, user: student, exam: create(:exam, lecture: lecture))
    expect_no_other_tie
    expect(in_audience?).to be(true)

    entry.update!(excluded_at: Time.current)

    expect(in_audience?).to be(false)
  end

  [:open, :closed, :processing].each do |campaign_status|
    it "takes in a pending registration in a #{campaign_status} campaign" do
      register(:pending, campaign_status)

      expect_no_other_tie
      expect(in_audience?).to be(true)
    end
  end

  it "leaves out a registration in a draft or a finished campaign" do
    register(:pending, :draft)
    register(:confirmed, :completed)

    expect(in_audience?).to be(false)
  end

  it "leaves out a rejected registration, without undoing another tie" do
    register(:rejected, :open)
    expect(in_audience?).to be(false)

    create(:lecture_bookmark, user: student, lecture: lecture)

    expect(in_audience?).to be(true)
  end

  it "names everybody once, however many ties they have" do
    create(:lecture_bookmark, user: student, lecture: lecture)
    create(:lecture_membership, user: student, lecture: lecture)

    expect(described_class.users(lecture.id).where(id: student.id).count).to eq(1)
    expect(described_class.lectures_of(student).where(id: lecture.id).count).to eq(1)
  end

  it "answers for several lectures at once and only for them" do
    other = create(:lecture, :released_for_all)
    unrelated = create(:lecture, :released_for_all)
    create(:lecture_bookmark, user: student, lecture: other)

    expect(described_class.users([lecture.id, other.id])).to include(student)
    expect(described_class.users(unrelated.id)).not_to include(student)
  end
end
