require "rails_helper"

RSpec.describe(Rosters::ParticipationCheck) do
  let(:term) { create(:term, :active) }
  let(:lecture) { create(:lecture, :released_for_all, term: term) }
  let(:student) { create(:confirmed_user) }
  let!(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
  let(:check) { described_class.new(student) }

  before { lecture.add_user_to_roster!(student) }

  it "asks someone enrolled in a lecture of the running term without any group" do
    expect(check.due?).to be(true)
    expect(check.lectures).to contain_exactly(lecture)
  end

  it "does not ask someone in a tutorial, a cohort or a talk of the lecture" do
    tutorial.add_user_to_roster!(student)
    expect(described_class.new(student).due?).to be(false)

    tutorial.remove_user_from_roster!(student)
    create(:cohort, context: lecture, propagate_to_lecture: false).add_user_to_roster!(student)
    expect(described_class.new(student).due?).to be(false)
  end

  it "does not ask again once the student said they take part" do
    lecture.lecture_memberships.find_by(user: student)
           .update!(participation_confirmed_at: Time.current)

    expect(check.due?).to be(false)
  end

  it "does not ask about a lecture without groups or of another term" do
    tutorial.destroy!
    expect(described_class.new(student).due?).to be(false)

    old = create(:lecture, :released_for_all, term: create(:term, year: 2020, season: "SS"))
    create(:tutorial, lecture: old, skip_campaigns: true)
    old.add_user_to_roster!(student)
    expect(described_class.new(student).due?).to be(false)
  end

  it "does not ask the lecture's tutors" do
    tutorial.tutors << student

    expect(check.due?).to be(false)
  end

  it "does not ask someone whose registration for a group still runs" do
    campaign = create(:registration_campaign, :open, campaignable: lecture)
    create(:registration_user_registration, :pending,
           user: student, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)

    expect(check.due?).to be(false)
  end

  it "answers in one query for someone who only waits for a group" do
    campaign = create(:registration_campaign, :open, campaignable: lecture)
    create(:registration_user_registration, :pending,
           user: student, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)
    queries = 0
    count = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }

    ActiveSupport::Notifications.subscribed(count, "sql.active_record") { check.due? }

    expect(check.due?).to be(false)
    expect(queries).to eq(1)
  end

  it "asks again after the student joined a group and lost it" do
    membership = lecture.lecture_memberships.find_by(user: student)
    membership.update!(participation_confirmed_at: Time.current)

    Rosters::MaintenanceService.new.add_user!(student, tutorial)
    Rosters::MaintenanceService.new.remove_user!(student, tutorial, notify: false)

    expect(membership.reload.participation_confirmed_at).to be_nil
    expect(described_class.new(student).due?).to be(true)
  end

  it "asks again after a campaign placed the student in a group they left" do
    membership = lecture.lecture_memberships.find_by(user: student)
    membership.update!(participation_confirmed_at: Time.current)

    tutorial.materialize_allocation!(user_ids: [student.id],
                                     campaign: create(:registration_campaign,
                                                      campaignable: lecture))

    expect(membership.reload.participation_confirmed_at).to be_nil
  end

  it "keeps the answer when the student joins an exam, which is no group" do
    membership = lecture.lecture_memberships.find_by(user: student)
    membership.update!(participation_confirmed_at: Time.current)

    Rosters::MaintenanceService.new.add_user!(student, create(:exam, lecture: lecture))

    expect(membership.reload.participation_confirmed_at).to be_present
  end
end
