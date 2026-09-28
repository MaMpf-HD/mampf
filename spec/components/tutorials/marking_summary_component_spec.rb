require "rails_helper"

RSpec.describe(MarkingSummaryComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  def summary(statuses)
    render_inline(described_class.new(statuses: statuses)).text.strip
  end

  it "counts who handed in and names every state that occurs" do
    expect(summary([:reviewed, :reviewed, :pending_grading, :not_submitted, :exempt]))
      .to eq("3 handed in · 2 reviewed · 1 pending grading · 1 not submitted · 1 exempt")
  end

  it "keeps quiet about states nobody is in, but always counts who handed in" do
    expect(summary([:not_submitted])).to eq("0 handed in · 1 not submitted")
  end

  it "names the teams behind the hand-ins when given" do
    component = described_class.new(statuses: [:reviewed, :reviewed, :pending_grading], teams: 2)
    expect(render_inline(component).text.strip)
      .to eq("3 handed in (2 teams) · 2 reviewed · 1 pending grading")
  end

  it "carries the id the row answers replace" do
    expect(render_inline(described_class.new(statuses: [])).css("p#marking-summary")).to be_present
  end
end
