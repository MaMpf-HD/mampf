require "rails_helper"

RSpec.describe(LectureSearchResultComponent, type: :component) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  def render_card(show_term: true, term: nil, **ids)
    render_inline(described_class.new(
                    lecture: lecture, user: user, term: term, show_term: show_term,
                    ids: described_class::PageIds.new(**ids)
                  ))
  end

  def bookmark_button(page)
    page.css("[data-testid='lecture-search-bookmark-button']").first
  end

  it "offers the bookmark for an open lecture nobody registered for" do
    page = render_card

    expect(bookmark_button(page)["aria-pressed"]).to eq("false")
    expect(page.css(".lecture-search-result-wrap").first["data-controller"])
      .to eq("bookmark")
  end

  it "bookmarks for the semester the search is scoped to" do
    wrapper = render_card(term: create(:term, :summer, year: 2031))
              .at_css(".lecture-search-result-wrap")

    expect(wrapper["data-bookmark-url-value"]).to end_with("?term=SS31")
  end

  it "shows a bookmarked lecture as pressed" do
    page = render_card(bookmarked_lecture_ids: Set[lecture.id])

    expect(bookmark_button(page)["aria-pressed"]).to eq("true")
    expect(page.css(".lecture-search-result-wrap.is-bookmarked")).to be_present
  end

  it "offers no bookmark for a lecture behind a pass phrase" do
    lecture.update!(passphrase: "open sesame")

    page = render_card

    expect(bookmark_button(page)).to be_nil
    expect(page.css(".lecture-search-result-wrap").first["data-controller"]).to be_nil
  end

  it "marks a pending registration with the dashboard's label and keeps the bookmark" do
    page = render_card(registration_status_by_lecture_id: { lecture.id => :pending })

    control = page.css("[data-testid='lecture-search-registered-control']").first
    expect(control["aria-label"])
      .to eq(I18n.t("registration.user_registration.status.pending"))
    expect(bookmark_button(page)).to be_nil
  end

  it "shows a self-enrolled seat as registered, with nothing left to do" do
    page = render_card(rosterized_lecture_ids: Set[lecture.id],
                       self_enrollable_lecture_ids: Set[lecture.id])

    control = page.css("[data-testid='lecture-search-registered-control']").first
    expect(control["aria-label"]).to eq(I18n.t("lecture.search.registered_status"))
    expect(page.css("[data-testid='lecture-search-register-link']")).to be_empty
    expect(bookmark_button(page)).to be_nil
  end

  it "offers registration while a campaign is open" do
    page = render_card(registration_status_by_lecture_id: { lecture.id => :open })

    expect(page.css("[data-testid='lecture-search-register-link']")).to be_present
    expect(page.css("[data-testid='lecture-search-registered-control']")).to be_empty
  end

  it "leaves the term out when asked to" do
    term = lecture.term.to_label_short

    expect(render_card.text).to include(term)
    expect(render_card(show_term: false).text).not_to include(term)
  end
end
