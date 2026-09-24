require "rails_helper"

RSpec.describe(LectureHomeHelper, type: :helper) do
  let(:campaign) { double(campaign: double(registration_deadline: 5.days.from_now)) }
  let(:exam) { double }

  def sheet(state, due_in)
    double(state: state, assignment: double(deadline: due_in.from_now))
  end

  def work(*due)
    double(due: due)
  end

  before do
    helper.extend(UserRegistrationsHelper)
    allow(helper).to receive(:registration_needs_action?).and_return(true)
  end

  it "leads with the campaign when it is due before the sheet" do
    focus = helper.lecture_home_focus(campaigns: [campaign],
                                      work: work(sheet(:nothing_handed_in, 7.days)),
                                      next_exam: exam)

    expect(focus.kind).to eq(:campaign)
  end

  it "leads with the sheet when it is due first" do
    focus = helper.lecture_home_focus(campaigns: [campaign],
                                      work: work(sheet(:nothing_handed_in, 2.days)),
                                      next_exam: exam)

    expect(focus.kind).to eq(:sheet)
  end

  it "passes over a sheet that is handed in already" do
    allow(helper).to receive(:registration_needs_action?).and_return(false)

    focus = helper.lecture_home_focus(campaigns: [campaign],
                                      work: work(sheet(:handed_in, 2.days)),
                                      next_exam: exam)

    expect(focus.kind).to eq(:exam)
  end

  it "leads with nothing when nothing is due" do
    expect(helper.lecture_home_focus(campaigns: [], work: nil, next_exam: nil)).to be_nil
  end
end
