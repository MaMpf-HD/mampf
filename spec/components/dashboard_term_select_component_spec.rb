require "rails_helper"

RSpec.describe(DashboardTermSelectComponent, type: :component) do
  let(:past) { create(:term, :winter, year: 2024) }
  let(:current) { create(:term, :summer, :active, year: 2025) }
  let(:future) { create(:term, :winter, year: 2025) }
  let(:terms) { [past, current, future] }

  def render_select(selected: current, id: "dashboard-term-select", anchor: nil)
    render_inline(described_class.new(terms: terms, selected: selected,
                                      id: id, anchor: anchor))
  end

  it "does not render for a single semester" do
    rendered = render_inline(described_class.new(terms: [current],
                                                 selected: current, id: "x"))

    expect(rendered.to_html).to be_blank
  end

  it "lists every semester newest first, each starting with its season" do
    labels = render_select.css("option").map(&:text)

    expect(labels).to eq(["WS 2025/26", "SS 2025", "WS 2024/25"])
  end

  it "points each option at its own term by semester slug" do
    values = render_select.css("option").pluck("value")

    expect(values).to contain_exactly("WS24-25", "SS25", "WS25-26")
  end

  it "preselects the current semester" do
    selected = render_select.css("option[selected]")

    expect(selected.size).to eq(1)
    expect(selected.first["value"]).to eq("SS25")
  end

  it "carries the shareable dashboard URL for each option separately" do
    urls = render_select.css("option").pluck("data-url")

    expect(urls).to contain_exactly("/?term=WS24-25",
                                    "/?term=SS25",
                                    "/?term=WS25-26")
  end

  it "keeps the search in view when given an anchor" do
    urls = render_select(anchor: "lecture-search").css("option").pluck("data-url")

    expect(urls).to all(end_with("#lecture-search"))
  end

  it "wires the select up to refresh the page on change" do
    rendered = render_select(id: "lecture-search-term-select")
    select = rendered.at_css("select")

    expect(rendered.at_css("div")["id"]).to eq("lecture-search-term-select-wrapper")
    expect(select["id"]).to eq("lecture-search-term-select")
    expect(select["data-testid"]).to eq("lecture-search-term-select")
    expect(select["data-action"]).to eq("change->dashboard-term-select#change")
  end
end
