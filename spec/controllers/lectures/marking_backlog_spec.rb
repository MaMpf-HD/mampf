require "rails_helper"

RSpec.describe(Lectures::MarkingBacklog) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:own) { create(:tutorial, lecture: lecture, title: "Mo 10") }
  let(:other) { create(:tutorial, lecture: lecture, title: "Di 14") }
  let(:marked_sheet) do
    create(:assignment, :expired, lecture: lecture, title: "Homework 1",
                                  expired_since: 2.days)
  end

  def hand_in(assignment, tutorial, **attrs)
    create(:assessment_participation, assessment: assignment.assessment,
                                      user: create(:confirmed_user), tutorial: tutorial,
                                      submitted_at: 3.days.ago, **attrs)
  end

  before do
    2.times { hand_in(marked_sheet, own) }
    hand_in(marked_sheet, other)
    hand_in(marked_sheet, own, status: :reviewed)
    hand_in(marked_sheet, own, submitted_at: nil)
    running = create(:assignment, lecture: lecture, title: "Homework 2",
                                  deadline: 1.week.from_now)
    hand_in(running, own)
  end

  it "counts the hand-ins waiting for points in the tutor's groups" do
    entries = described_class.new(lecture, tutorials: [own]).entries

    expect(entries.map { |e| [e.assignment.title, e.tutorial.title, e.people] })
      .to eq([["Homework 1", "Mo 10", 2]])
  end

  it "counts every group for the lecturer" do
    backlog = described_class.new(lecture)

    expect(backlog.entries.map { |e| [e.tutorial.title, e.people] })
      .to contain_exactly(["Mo 10", 2], ["Di 14", 1])
    expect(backlog.total).to eq(3)
  end

  it "counts nothing for a tutor without groups" do
    expect(described_class.new(lecture, tutorials: []).entries).to be_empty
  end
end
