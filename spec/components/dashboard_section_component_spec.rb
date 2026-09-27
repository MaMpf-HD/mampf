require "rails_helper"

RSpec.describe(DashboardSectionComponent, type: :component) do
  def render_section(title: "You bookmarked these", testid: "dashboard-bookmarked")
    render_inline(described_class.new(title: title, testid: testid)) do
      "<article>a card</article>".html_safe
    end
  end

  it "does not render without any cards" do
    rendered = render_inline(described_class.new(title: "x", testid: "y"))

    expect(rendered.to_html).to be_blank
  end

  it "wires the label up as a disclosure button for the cards" do
    rendered = render_section

    toggle = rendered.at_css(".dashboard-section__toggle")
    cards = rendered.at_css(".dashboard-cards")

    expect(toggle["aria-expanded"]).to eq("true")
    expect(toggle["aria-controls"]).to eq("dashboard-bookmarked-cards")
    expect(cards["id"]).to eq("dashboard-bookmarked-cards")
  end

  it "keeps the button inside the labelled heading" do
    rendered = render_section

    heading = rendered.at_css("h2.dashboard-section__label")

    expect(heading["id"]).to eq("dashboard-bookmarked-heading")
    expect(heading.at_css("button.dashboard-section__toggle")).to be_present
    expect(rendered.at_css("section")["aria-labelledby"])
      .to eq("dashboard-bookmarked-heading")
  end

  it "carries the caret and the collapse controller keyed to the band" do
    rendered = render_section

    section = rendered.at_css("section.dashboard-section")

    expect(section["data-controller"]).to eq("dashboard-section")
    expect(section["data-dashboard-section-key-value"]).to eq("dashboard-bookmarked")
    expect(rendered.at_css(".dashboard-section__caret")["aria-hidden"]).to eq("true")
  end
end
