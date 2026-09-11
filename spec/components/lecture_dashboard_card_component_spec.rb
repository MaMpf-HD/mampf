require "rails_helper"

RSpec.describe(LectureDashboardCardComponent, type: :component) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }

  before do
    user.subscribe_lecture!(lecture)
  end

  def render_card(**)
    render_inline(described_class.new(lecture: lecture, user: user, **))
  end

  it "renders the lecture on a tilted card" do
    card = render_card.at_css("[data-testid='lecture-dashboard-card']")

    expect(card["style"]).to match(/--dashboard-card-tilt: -?\d/)
    expect(card.text).to include(lecture.title_no_term)
  end

  it "dyes the card in the tape colour, so the border can follow it" do
    Dashboard::CardStyle.create!(user: user, lecture: lecture,
                                 tape_color: "mint")

    card = render_card.at_css("[data-testid='lecture-dashboard-card']")

    expect(card["style"]).to include("--washi-tape-color: var(--washi-tape-color-mint)")
  end

  it "falls back to a seeded colour when the user has not picked one" do
    card = render_card.at_css("[data-testid='lecture-dashboard-card']")

    tape = Dashboard::WashiTape.for(seed: lecture.id)
    expect(card["style"]).to include("var(--washi-tape-color-#{tape.color})")
  end

  it "offers the colour picker" do
    rendered = render_card

    expect(rendered.at_css("[data-testid='washi-tape-strip']")).to be_present
    expect(rendered.at_css("[data-testid='washi-tape']")["data-washi-tape-url-value"])
      .to eq("/dashboard/washi_tape/#{lecture.id}")
    expect(rendered.css(".washi-tape__swatch").size)
      .to eq(Dashboard::WashiTape::COLORS.size)
  end

  it "pins the quick actions beside the card, outside its stretched link" do
    create(:assignment, lecture: lecture, deadline: 2.days.from_now)

    rendered = render_card

    expect(rendered.at_css(".dashboard-card [data-testid='lecture-quick-actions']"))
      .to be_nil
    expect(rendered.at_css(".dashboard-card-slot__rail " \
                           "[data-testid='lecture-quick-actions']")).to be_present
  end

  it "leaves the rail out entirely when there is nothing to act on" do
    expect(render_card.at_css(".dashboard-card-slot__rail")).to be_nil
  end

  it "no longer carries a bookmark toggle" do
    expect(render_card.at_css(".bi-bookmark, .bi-bookmark-fill")).to be_nil
  end

  it "carries no remove-bookmark control by default" do
    expect(render_card.at_css("[data-controller='bookmark-removal']")).to be_nil
  end

  context "when the card sits in the bookmarked band" do
    it "offers a remove-bookmark control wired to the lecture" do
      rendered = render_card(bookmarked: true)

      control = rendered.at_css("[data-controller='bookmark-removal']")
      expect(control["data-bookmark-removal-url-value"])
        .to eq("/dashboard/bookmarks/#{lecture.id}")
      expect(rendered.at_css("[data-action='bookmark-removal#open']"))
        .to be_present
    end
  end

  context "with a registration status" do
    let(:campaign) do
      create(:registration_campaign, :open, campaignable: lecture)
    end

    it "does not show a badge for a confirmed registration - the band already says so" do
      create(:registration_user_registration, :confirmed,
             user: user, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      rendered = render_card

      expect(rendered.text).not_to include(
        I18n.t("registration.user_registration.status.confirmed")
      )
    end

    it "shows a badge for a pending registration" do
      create(:registration_user_registration, :pending,
             user: user, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      rendered = render_card

      expect(rendered.text).to include(
        I18n.t("registration.user_registration.status.pending")
      )
    end

    it "shows a badge and a removal control for a rejected registration" do
      closed_campaign = create(:registration_campaign, :closed,
                               campaignable: lecture)
      create(:registration_user_registration, :rejected,
             user: user, registration_campaign: closed_campaign,
             registration_item: closed_campaign.registration_items.first)

      rendered = render_card

      expect(rendered.text).to include(
        I18n.t("registration.user_registration.status.rejected")
      )
      control = rendered.at_css("[data-controller='registration-notice-removal']")
      expect(control["data-registration-notice-removal-url-value"])
        .to eq("/dashboard/registration_notice/#{lecture.id}")
    end
  end
end
