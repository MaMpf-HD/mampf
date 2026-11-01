require "rails_helper"

RSpec.describe(Rosters::EnrollmentReconciliation) do
  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
  let(:service) { Rosters::MaintenanceService.new }
  let(:reconciliation) { described_class.new }

  # Enrolls the user without any group, as data from before enrollment was tied
  # to groups can look.
  def enroll_without_place(user)
    lecture.add_user_to_roster!(user)
    create(:lecture_bookmark, lecture: lecture, user: user)
  end

  describe "#rows" do
    it "counts who is enrolled without a place, and of them who is where else" do
      seated, on_exam = create_list(:confirmed_user, 2)
      service.add_user!(seated, tutorial, ignore_capacity: true)
      service.add_user!(on_exam, create(:exam, :without_campaign, lecture: lecture))
      on_list, waiting = create_list(:confirmed_user, 2)
      [on_list, waiting].each { |user| enroll_without_place(user) }
      create(:cohort, context: lecture).add_user_to_roster!(on_list)
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: waiting, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      row = reconciliation.rows.sole

      expect(row.to_h.except(:lecture))
        .to eq(enrolled: 4, without_place: 2, lists_only: 1, awaiting: 1, admitted: 0,
               staff: 0)
    end

    # An admitted student who is taken off needs a group before they can
    # register for a resit, so the lecturer has to know about them.
    it "counts the admitted among those it would take off" do
      admitted = create(:confirmed_user)
      enroll_without_place(admitted)
      create(:student_performance_certification, :passed, lecture: lecture, user: admitted)

      expect(reconciliation.rows.sole.admitted).to eq(1)
    end
  end

  describe "#apply!" do
    let(:limbo) { create(:confirmed_user) }

    before { enroll_without_place(limbo) }

    it "takes off who has no place, as left without anybody's doing, bookmark included" do
      expect(reconciliation.apply!).to eq(1)

      membership = lecture.excluded_lecture_memberships.find_by(user: limbo)
      expect(membership.excluded_by).to be_nil
      expect(limbo.reload.lectures).not_to include(lecture)
    end

    # Joining a group takes the same lock (see
    # Rosters::MaintenanceService#add_user!), so a group joined meanwhile is not
    # missed.
    it "decides under the lecture's lock" do
      enrolled_at_lock = nil
      allow_any_instance_of(Lecture).to receive(:with_lock).and_wrap_original do |original, &block|
        enrolled_at_lock = lecture.lecture_memberships.exists?(user: limbo)
        original.call(&block)
      end

      reconciliation.apply!

      expect(enrolled_at_lock).to be(true)
      expect(lecture.lecture_memberships.exists?(user: limbo)).to be(false)
    end

    it "keeps their list, so that they stay in its audience" do
      list = create(:cohort, context: lecture)
      list.add_user_to_roster!(limbo)

      reconciliation.apply!

      expect(list.reload.members).to include(limbo)
    end

    it "leaves whoever is on an exam list alone" do
      create(:exam, :without_campaign, lecture: lecture).add_user_to_roster!(limbo)

      expect(reconciliation.apply!).to eq(0)
      expect(lecture.reload.members).to include(limbo)
    end

    it "keeps a tutor of the lecture, and reports them" do
      create(:tutor_tutorial_join, tutorial: tutorial, tutor: limbo)

      expect(reconciliation.apply!).to eq(0)
      expect(limbo.reload.lectures).to include(lecture)
      expect(reconciliation.report.join("\n")).to include("1 staff")
    end

    it "keeps a tutor by a redeemed voucher who has no tutorial yet" do
      Redemption.create!(voucher: create(:voucher, :tutor, lecture: lecture), user: limbo)

      expect(reconciliation.apply!).to eq(0)
      expect(lecture.reload.members).to include(limbo)
    end

    it "keeps a tutor of a cohort" do
      CohortTutorJoin.create!(cohort: create(:cohort, context: lecture), tutor: limbo)

      expect(reconciliation.apply!).to eq(0)
      expect(lecture.reload.members).to include(limbo)
    end

    it "keeps to the lectures it is narrowed to" do
      other = create(:lecture)
      stray = create(:confirmed_user)
      other.add_user_to_roster!(stray)

      expect(described_class.new(lecture_ids: [other.id]).apply!).to eq(1)
      expect(lecture.reload.members).to include(limbo)
    end

    it "leaves members with a place alone" do
      seated = create(:confirmed_user)
      service.add_user!(seated, tutorial, ignore_capacity: true)

      reconciliation.apply!

      expect(lecture.reload.members).to include(seated)
    end
  end

  it "finds nothing after joining, moving and losing places" do
    users = create_list(:confirmed_user, 3)
    other = create(:tutorial, lecture: lecture, skip_campaigns: true)
    cohort = create(:cohort, :enrollment, context: lecture)
    users.each { |user| service.add_user!(user, tutorial, ignore_capacity: true) }
    service.move_user!(users[0], tutorial, other, ignore_capacity: true)
    service.add_user!(users[1], cohort, ignore_capacity: true)
    service.remove_user!(users[1], tutorial)
    service.remove_user!(users[2], tutorial)

    expect(reconciliation.rows).to be_empty
    expect(lecture.reload.members).to contain_exactly(users[0], users[1])
  end

  describe "#report" do
    it "names a running campaign whose allocation would seat people twice" do
      student = create(:confirmed_user)
      service.add_user!(student, tutorial, ignore_capacity: true)
      campaign = create(:registration_campaign, :open, campaignable: lecture,
                                                       description: "Sign-up")
      create(:registration_user_registration, :confirmed,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      line = reconciliation.report.find { |text| text.include?("\"Sign-up\" (open)") }
      expect(line).to include("1 registered would be moved out of their tutorial")
    end

    it "names a campaign closed long ago and never finalized" do
      create(:registration_campaign, :closed, campaignable: lecture, description: "Stale",
                                              registration_deadline: 1.year.ago)

      line = reconciliation.report.find { |text| text.include?("\"Stale\" (closed)") }
      expect(line).to include("never finalized")
    end

    it "calls a term over only before the running one, not the next" do
      running = create(:term, year: 2030, season: "WS", active: true)
      next_term = create(:term, year: 2031, season: "SS")
      past = create(:term, year: 2030, season: "SS")
      [next_term, past].each_with_index do |term, i|
        create(:registration_campaign, :open,
               campaignable: create(:lecture, term: term), description: "Campaign #{i}",
               registration_deadline: 1.year.from_now)
      end

      expect(running).to be_active
      lines = reconciliation.report
      expect(lines.find { |text| text.include?("Campaign 0") }).not_to include("term is over")
      expect(lines.find { |text| text.include?("Campaign 1") }).to include("its term is over")
    end
  end
end
