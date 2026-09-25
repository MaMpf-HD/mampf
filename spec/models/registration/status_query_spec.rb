require "rails_helper"

RSpec.describe(Registration::StatusQuery) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  def status
    described_class.new(user, [lecture.id]).statuses[lecture.id]
  end

  def campaign(*traits)
    create(:registration_campaign, *traits, :with_items, campaignable: lecture)
  end

  def register(campaign, *traits)
    create(:registration_user_registration, *traits,
           user: user, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)
  end

  it "says nothing for a lecture without a campaign, or with a draft only" do
    campaign(:draft)

    expect(status).to be_nil
  end

  it "is open while the student may still register" do
    campaign(:open)

    expect(status).to eq(:open)
  end

  it "is pending for a registration still waiting for allocation" do
    register(campaign(:closed), :pending)

    expect(status).to eq(:pending)
  end

  it "prefers a confirmed registration over a pending one elsewhere" do
    register(campaign(:closed), :pending)
    register(campaign(:completed), :confirmed)

    expect(status).to eq(:confirmed)
  end

  it "prefers a pending registration over a rejected one elsewhere" do
    register(campaign(:completed), :rejected)
    register(campaign(:closed), :pending)

    expect(status).to eq(:pending)
  end

  it "prefers an open campaign over a rejection" do
    register(campaign(:completed), :rejected)
    campaign(:open)

    expect(status).to eq(:open)
  end

  it "shows a rejection until the student dismisses it" do
    registration = register(campaign(:completed), :rejected)
    expect(status).to eq(:rejected)

    registration.update!(dismissed_at: Time.current)

    expect(status).to be_nil
  end

  it "leaves exam campaigns out" do
    exam = create(:exam, lecture: lecture)
    # rubocop:disable Rails/SkipsModelValidations
    exam.registration_campaign.update_columns(status: Registration::Campaign.statuses[:open])
    # rubocop:enable Rails/SkipsModelValidations

    expect(status).to be_nil
  end

  it "answers for a whole page of lectures in a fixed number of queries" do
    lectures = create_list(:lecture, 3, :released_for_all)
    lectures.each do |each|
      create(:registration_campaign, :open, :with_items, campaignable: each)
    end
    user
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      described_class.new(user, lectures.map(&:id)).statuses
    end

    expect(queries).to eq(2)
  end
end
