require "rails_helper"

RSpec.describe(PointingSummaryComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  def summary(statuses)
    render_inline(described_class.new(statuses: statuses)).text.strip
  end

  it "counts the hand-ins and names every state that occurs" do
    expect(summary([:reviewed, :reviewed, :pending_grading, :not_submitted, :exempt]))
      .to eq("3 hand-ins · 2 marked · 1 not yet marked · 1 not submitted · 1 exempt")
  end

  it "keeps quiet about states nobody is in, but always counts the hand-ins" do
    expect(summary([:not_submitted])).to eq("0 hand-ins · 1 not submitted")
  end

  it "carries the id the row answers replace" do
    expect(render_inline(described_class.new(statuses: [])).css("p#pointing-summary")).to be_present
  end
end
