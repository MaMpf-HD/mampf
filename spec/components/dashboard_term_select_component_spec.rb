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

  it "lists every semester newest first, spelled out" do
    labels = render_select.css("option").map(&:text)

    expect(labels).to eq([future.to_long_label,
                          current.to_long_label,
                          past.to_long_label])
  end

  it "points each option at its own term" do
    values = render_select.css("option").pluck("value")

    expect(values).to contain_exactly("/?term=#{future.id}",
                                      "/?term=#{current.id}",
                                      "/?term=#{past.id}")
  end

  it "preselects the current semester" do
    selected = render_select.css("option[selected]")

    expect(selected.size).to eq(1)
    expect(selected.first["value"]).to eq("/?term=#{current.id}")
  end

  it "keeps the search in view when given an anchor" do
    values = render_select(anchor: "lecture-search").css("option").pluck("value")

    expect(values).to all(end_with("#lecture-search"))
  end

  it "wires the select up for a Turbo visit on change" do
    select = render_select(id: "lecture-search-term-select").at_css("select")

    expect(select["id"]).to eq("lecture-search-term-select")
    expect(select["data-testid"]).to eq("lecture-search-term-select")
    expect(select["data-action"]).to eq("change->dashboard-term-select#visit")
  end
end
