require "rails_helper"

RSpec.describe(SheetNewsComponent, type: :component) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:lecture) { create(:lecture) }

  def sheet(title, id:, correction: false, points: false)
    instance_double(Assessment::SubmissionsHub::Sheet,
                    news?: correction || points,
                    new_correction?: correction, new_points?: points,
                    assignment: instance_double(Assignment, title: title, id: id,
                                                            to_key: [id],
                                                            model_name: Assignment.model_name))
  end

  def render_news(*sheets)
    render_inline(described_class.new(sheets: sheets, lecture: lecture))
    rendered_content
  end

  # The row's report replaces this by id, so the id has to be there to replace
  # even when there is nothing left to say.
  it "keeps its place on the page when there is nothing new" do
    content = render_news(sheet("Homework 8", id: 8))

    expect(content).to include("id=\"sheet-news\"")
    expect(content).not_to include("news-row")
  end

  it "names the sheet, links to its row and says what arrived" do
    content = render_news(sheet("Homework 8", id: 8, correction: true))

    expect(content).to include(I18n.t("submission.hub.news.lead"))
    expect(content).to include("href=\"#sheet_assignment_8\"")
    expect(content).to include("Homework 8</a> (correction)")
    expect(content).to include(I18n.t("submission.hub.news.seen_all"))
    expect(content).to include("action=\"/lectures/#{lecture.id}/submissions/seen_all\"")
  end

  it "tells points from a correction, and names both when both are new" do
    content = render_news(sheet("Homework 8", id: 8, points: true),
                          sheet("Homework 7", id: 7, correction: true, points: true))

    expect(content).to include("Homework 8</a> (points)")
    expect(content).to include("Homework 7</a> (correction and points)")
  end

  it "names three sheets and counts the rest" do
    content = render_news(*(1..5).map { |n| sheet("Homework #{n}", id: n, points: true) })

    expect(content).to include("Homework 3</a>")
    expect(content).not_to include("Homework 4")
    expect(content).to include(I18n.t("submission.hub.news.more", count: 2))
  end

  it "skips a sheet with nothing new" do
    content = render_news(sheet("Homework 8", id: 8),
                          sheet("Homework 7", id: 7, correction: true))

    expect(content).not_to include("Homework 8")
    expect(content).to include("Homework 7</a>")
  end
end
