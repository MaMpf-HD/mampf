require "rails_helper"

RSpec.describe(TalkDashboardCardComponent, type: :component) do
  let(:user) { create(:confirmed_user) }
  let(:seminar) { create(:lecture, sort: "seminar") }
  let(:talk) { create(:talk, lecture: seminar) }

  before do
    talk.speakers << user
  end

  def render_card
    render_inline(described_class.new(talk: talk, user: user))
  end

  it "renders the talk on a card" do
    card = render_card.at_css("[data-testid='talk-dashboard-card']")

    expect(card.text).to include(talk.title)
  end

  it "offers the colour picker, keyed to the seminar" do
    rendered = render_card

    expect(rendered.at_css("[data-testid='washi-tape-strip']")).to be_present
    expect(rendered.at_css("[data-testid='washi-tape']")["data-washi-tape-url-value"])
      .to eq("/dashboard/washi_tape/#{seminar.id}")
  end

  it "shows the colour picked for the seminar" do
    Dashboard::CardStyle.create!(user: user, lecture: seminar,
                                 tape_color: "rose")

    card = render_card.at_css("[data-testid='talk-dashboard-card']")

    expect(card["style"]).to include("--washi-tape-color: var(--washi-tape-color-rose)")
  end
end
