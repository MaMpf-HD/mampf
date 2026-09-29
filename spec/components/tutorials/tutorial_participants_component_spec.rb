require "rails_helper"

RSpec.describe(TutorialParticipantsComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  around { |example| I18n.with_locale(:en) { example.run } }

  def run_registration(traits, user:, status: :confirmed, rank: nil)
    campaign = create(:registration_campaign, *traits, campaignable: lecture)
    item = create(:registration_item, registration_campaign: campaign, registerable: tutorial)
    create(:registration_user_registration, status, registration_campaign: campaign,
                                                    registration_item: item, user: user,
                                                    preference_rank: rank)
    campaign.update!(status: :open)
    campaign
  end

  it "lists the group's members by last name, with program and address to copy" do
    zimmer = create(:confirmed_user, first_name: "Anna", last_name: "Zimmer")
    becker = create(:confirmed_user, first_name: "Clara", last_name: "Becker",
                                     program: create(:program, degree: :msc))
    [zimmer, becker].each { |user| create(:tutorial_membership, tutorial: tutorial, user: user) }

    html = render_inline(described_class.new(tutorial: tutorial))

    rows = html.css("tbody tr").map { |row| row.css("td").first(2).map { |cell| cell.text.strip } }
    expect(rows).to eq([["Clara Becker", becker.program.name_with_subject], ["Anna Zimmer", ""]])
    expect(html.at_css("button[aria-label='Copy email address: #{becker.email}']")).to be_present
  end

  it "says so when nobody is in the group" do
    text = render_inline(described_class.new(tutorial: tutorial)).text.squish

    expect(text).to include(I18n.t("tutorial.participants.none"))
    expect(text).not_to include(I18n.t("tutorial.participants.registered_title"))
  end

  it "lists who registered while a first come, first served registration runs" do
    registrant = create(:confirmed_user, first_name: "Ada", last_name: "Lovelace")
    run_registration([:first_come_first_served], user: registrant)

    text = render_inline(described_class.new(tutorial: tutorial)).text.squish

    expect(text).to include(I18n.t("tutorial.participants.registered_title"), "Ada Lovelace")
  end

  # A wish says nothing about who gets in until the allocation has run.
  it "names nobody while a preference registration has not allocated" do
    registrant = create(:confirmed_user, first_name: "Ada", last_name: "Lovelace")
    campaign = run_registration([:preference_based], user: registrant, status: :pending, rank: 1)

    text = render_inline(described_class.new(tutorial: tutorial)).text.squish

    expect(text).to include(I18n.t("tutorial.participants.allocation_pending",
                                   campaign: campaign.description,
                                   deadline: I18n.l(campaign.registration_deadline,
                                                    format: :short)).squish)
    expect(text).not_to include("Ada Lovelace")
  end
end
