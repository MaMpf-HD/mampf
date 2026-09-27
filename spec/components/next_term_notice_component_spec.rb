require "rails_helper"

RSpec.describe(NextTermNoticeComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  let!(:current) { create(:term, :summer, :active, year: 2025) }
  let!(:upcoming) { create(:term, :winter, year: 2025) }

  def render_notice(selected: current)
    render_inline(described_class.new(selected: selected))
  end

  it "does not render without published lectures in the next term" do
    create(:lecture, term: upcoming)
    create(:lecture, :released_for_all, :term_independent)

    expect(render_notice.to_html).to be_blank
  end

  context "with published lectures in the next term" do
    before do
      create_list(:lecture, 2, :released_for_all, term: upcoming)
      create(:lecture, term: upcoming)
      create(:lecture, :released_for_all, term: current)
      create(:lecture, :released_for_all, :term_independent)
    end

    it "counts the published lectures of the next term and term-independent ones" do
      expect(render_notice.text).to include("3 lectures for WS 25/26")
    end

    it "links to the lecture search of the next term" do
      link = render_notice.at_css("a")

      expect(link["href"]).to eq("/?term=WS25-26#lecture-search")
    end

    it "does not render when the next term is already selected" do
      expect(render_notice(selected: upcoming).to_html).to be_blank
    end
  end

  it "does not render without a next term" do
    upcoming.destroy

    expect(render_notice.to_html).to be_blank
  end
end
