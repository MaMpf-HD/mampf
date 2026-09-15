require "rails_helper"

# The shape of the demo term rather than its contents: the student's page leads
# with the sheet that can still be handed in, and without one the action card
# has nothing to offer - which is the state a reviewer is least interested in.
RSpec.describe(Demo::AssessmentSetupSupport, type: :model) do
  def deadlines
    Demo::SetupSupport.send(:demo_assignment_attributes).pluck(:deadline)
  end

  it "leaves one sheet open, so the action card has something to show" do
    expect(deadlines.count(&:future?)).to eq(1)
  end

  # Closed but not long closed: that is the sheet the list shows as waiting to
  # be marked.
  it "keeps a sheet that closed within the week" do
    recent = deadlines.select(&:past?)
                      .select { |deadline| deadline > 1.week.ago }

    expect(recent.size).to eq(1)
  end
end
