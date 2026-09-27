require "rails_helper"

RSpec.describe(DashboardTermSelectComponent, type: :component) do
  let(:past) { create(:term, :winter, year: 2024) }
  let(:current) { create(:term, :summer, :active, year: 2025) }
  let(:future) { create(:term, :winter, year: 2025) }
  let(:terms) { [past, current, future] }

  def render_select(selected: current, id: "dashboard-term-select", anchor: nil)
    render_inline(described_class.new(
                    terms: terms, selected: selected, id: id, anchor: anchor,
                    next_term_lecture_count:
                      Dashboard::TermSelector.next_term_lecture_count
                  ))
  end

  it "does not render for a single semester" do
    rendered = render_inline(described_class.new(terms: [current],
                                                 selected: current, id: "x",
                                                 next_term_lecture_count: 0))

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

  it "offers to jump back to the current semester when another one is selected" do
    link = render_select(selected: past).at_css("[data-testid=current-term-link]")

    expect(link["data-dashboard-term-select-term-param"]).to eq("SS25")
  end

  it "does not offer to jump back when the current semester is selected" do
    expect(render_select.at_css("[data-testid=current-term-link]")).to be_nil
  end

  describe "next semester notice" do
    around { |example| I18n.with_locale(:en) { example.run } }

    def notice(**)
      render_select(**).at_css("[data-testid=next-term-notice]")
    end

    it "is hidden while the next semester has no published lectures" do
      create(:lecture, term: future)

      expect(notice).to be_nil
    end

    it "is hidden while the next semester has only term-independent lectures" do
      create(:lecture, :released_for_all, :term_independent)

      expect(notice).to be_nil
    end

    context "with published lectures in the next semester" do
      before do
        create_list(:lecture, 2, :released_for_all, term: future)
        create(:lecture, term: future)
        create(:lecture, :released_for_all, :term_independent)
      end

      it "counts the published lectures the search shows for the next semester" do
        expect(notice.text).to include("3 lectures for WS 25/26")
      end

      it "jumps down to the lecture search of the next semester" do
        link = notice.at_css("a")

        expect(link["href"]).to eq("/?term=WS25-26#lecture-search")
        expect(link["data-action"]).to be_nil
        expect(link.at_css(".bi-chevron-down")).to be_present
      end

      it "only switches the picker when it sits in the search" do
        link = notice(anchor: "lecture-search").at_css("a")

        expect(link["data-action"]).to eq("dashboard-term-select#pick")
        expect(link["data-dashboard-term-select-term-param"]).to eq("WS25-26")
        expect(link.at_css(".bi-chevron-down")).to be_nil
      end

      it "is hidden when another than the current semester is selected" do
        expect(notice(selected: past)).to be_nil
        expect(notice(selected: future)).to be_nil
      end
    end

    context "without a next semester" do
      let(:terms) { [past, current] }

      it "is hidden even with published term-independent lectures" do
        create(:lecture, :released_for_all, :term_independent)

        expect(notice).to be_nil
      end
    end
  end
end
