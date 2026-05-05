require "rails_helper"

RSpec.describe(Exam, type: :model) do
  describe "Registration::Registerable" do
    it_behaves_like "a registerable model"
  end

  describe "Rosters::Rosterable" do
    it_behaves_like "a rosterable model"
  end

  describe "validations" do
    describe "registration_deadline" do
      it "is invalid when deadline is in the past on create" do
        exam = build(:exam, :with_date, registration_deadline: 1.day.ago)

        expect(exam).to be_invalid
        expect(exam.errors.where(:registration_deadline, :must_be_in_future))
          .to be_present
      end

      it "is valid when deadline is in the future on create" do
        exam = build(:exam, :with_date,
                     registration_deadline: 3.days.from_now)

        expect(exam).to be_valid
      end

      it "is invalid when deadline is after the exam date" do
        exam = build(:exam, date: 1.week.from_now,
                            registration_deadline: 2.weeks.from_now)

        expect(exam).to be_invalid
        expect(exam.errors.where(:registration_deadline, :must_be_before_exam_date))
          .to be_present
      end

      context "on update with an active campaign" do
        let(:exam) { create(:exam, date: 2.weeks.from_now) }

        before do
          allow(Flipper).to receive(:enabled?).and_call_original
          allow(Flipper).to receive(:enabled?)
            .with(:registration_campaigns).and_return(true)
          exam.registration_campaign&.update!(status: :open)
        end

        it "is invalid when deadline is changed to the past" do
          exam.registration_deadline = 1.day.ago
          expect(exam).to be_invalid
        end

        it "is valid when deadline is changed to the future" do
          exam.registration_deadline = exam.date - 1.day
          expect(exam).to be_valid
        end
      end

      context "on update with a completed campaign" do
        let(:exam) { create(:exam, :with_date) }

        before do
          allow(Flipper).to receive(:enabled?).and_call_original
          allow(Flipper).to receive(:enabled?)
            .with(:registration_campaigns).and_return(true)
          # rubocop:disable Rails/SkipsModelValidations
          exam.registration_campaign&.update_column(
            :status,
            Registration::Campaign.statuses[:completed]
          )
          # rubocop:enable Rails/SkipsModelValidations
        end

        it "allows a past deadline (campaign already finished)" do
          exam.registration_deadline = 1.day.ago
          expect(exam).to be_valid
        end
      end
    end
  end

  describe "associations" do
    it "has many exam_roster_entries" do
      exam = create(:exam)
      create_list(:exam_roster_entry, 3, exam: exam)

      expect(exam.exam_roster_entries.count).to eq(3)
    end

    it "has many users through exam_roster_entries" do
      exam = create(:exam)
      users = create_list(:confirmed_user, 3)
      users.each { |user| create(:exam_roster_entry, exam: exam, user: user) }

      expect(exam.users.count).to eq(3)
    end

    it "destroys dependent exam_roster_entries when destroyed" do
      exam = create(:exam)
      create_list(:exam_roster_entry, 3, exam: exam)

      expect(exam.reload.destructible?).to be(false)

      exam.exam_roster_entries.destroy_all

      expect { exam.destroy }.not_to raise_error
    end
  end

  describe "concerns" do
    it "includes Registration::Registerable" do
      expect(Exam.ancestors).to include(Registration::Registerable)
    end

    it "includes Rosters::Rosterable" do
      expect(Exam.ancestors).to include(Rosters::Rosterable)
    end
  end

  describe "roster methods" do
    let(:exam) { create(:exam) }
    let(:users) { create_list(:confirmed_user, 3) }

    before do
      users.each { |user| create(:exam_roster_entry, exam: exam, user: user) }
    end

    it "#roster_entries returns exam_roster_entries" do
      expect(exam.roster_entries).to eq(exam.exam_roster_entries)
    end

    it "#roster_association_name returns :exam_roster_entries" do
      expect(exam.roster_association_name).to eq(:exam_roster_entries)
    end

    it "#allocated_user_ids returns user IDs" do
      expect(exam.allocated_user_ids).to match_array(users.map(&:id))
    end

    it "excludes soft-removed roster rows from active roster queries" do
      excluded_user = create(:confirmed_user)
      create(:exam_roster_entry,
             exam: exam,
             user: excluded_user,
             excluded_at: Time.current)

      expect(exam.exam_roster_entries.map(&:user_id)).not_to include(excluded_user.id)
      expect(exam.excluded_exam_roster_entries.map(&:user_id)).to include(excluded_user.id)
      expect(exam.allocated_user_ids).not_to include(excluded_user.id)
    end
  end

  describe "exam roster exclusions" do
    let(:exam) { create(:exam, :with_date) }
    let(:user) { create(:confirmed_user) }

    before do
      Flipper.enable(:registration_campaigns)
      create(:exam_roster_entry, exam: exam, user: user)
    end

    after do
      Flipper.disable(:registration_campaigns)
    end

    it "soft-removes participants after finalization" do
      exam.registration_campaign.update!(status: :completed)
      roster_entry = exam.all_exam_roster_entries.find_by!(user: user)

      expect do
        exam.remove_user_from_roster!(user)
      end.not_to change(ExamRosterEntry, :count)

      expect(roster_entry.reload.excluded_at).to be_present
      expect(exam.exam_roster_entries).to be_empty
      expect(exam.excluded_exam_roster_entries).to include(roster_entry)
    end

    it "reinstates excluded participants when they are added again" do
      exam.registration_campaign.update!(status: :completed)
      roster_entry = exam.all_exam_roster_entries.find_by!(user: user)
      exam.remove_user_from_roster!(user)

      expect do
        exam.add_user_to_roster!(user)
      end.not_to change(ExamRosterEntry, :count)

      expect(roster_entry.reload.excluded_at).to be_nil
      expect(exam.exam_roster_entries).to include(roster_entry)
    end

    it "keeps destroying roster rows before finalization" do
      expect do
        exam.remove_user_from_roster!(user)
      end.to change(ExamRosterEntry, :count).by(-1)
    end
  end

  describe "#status_phase" do
    let(:lecture) { create(:lecture) }

    context "with a draft campaign" do
      let(:exam) { create(:exam, :with_date, lecture: lecture) }

      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?)
          .with(:registration_campaigns).and_return(true)
      end

      it "returns :draft" do
        expect(exam.status_phase).to eq(:draft)
      end
    end

    context "with an open campaign" do
      let(:exam) { create(:exam, date: 2.weeks.from_now, lecture: lecture) }

      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?)
          .with(:registration_campaigns).and_return(true)
        exam.registration_campaign.update!(status: :open)
      end

      it "returns :registration_open" do
        expect(exam.status_phase).to eq(:registration_open)
      end
    end

    context "with a closed campaign" do
      let(:exam) { create(:exam, :with_date, lecture: lecture) }

      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?)
          .with(:registration_campaigns).and_return(true)
        # rubocop:disable Rails/SkipsModelValidations
        exam.registration_campaign
            .update_column(:status, Registration::Campaign.statuses[:closed])
        # rubocop:enable Rails/SkipsModelValidations
      end

      it "returns :registration_closed" do
        expect(exam.status_phase).to eq(:registration_closed)
      end
    end

    context "with a completed campaign and future date" do
      let(:exam) { create(:exam, date: 2.weeks.from_now, lecture: lecture) }

      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?)
          .with(:registration_campaigns).and_return(true)
        # rubocop:disable Rails/SkipsModelValidations
        exam.registration_campaign
            .update_column(:status, Registration::Campaign.statuses[:completed])
        # rubocop:enable Rails/SkipsModelValidations
      end

      it "returns :finalized" do
        expect(exam.status_phase).to eq(:finalized)
      end
    end

    context "with a completed campaign and past date, no grading" do
      let(:exam) { create(:exam, date: 1.week.ago, lecture: lecture) }

      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?)
          .with(:registration_campaigns).and_return(true)
        # rubocop:disable Rails/SkipsModelValidations
        exam.registration_campaign
            .update_column(:status, Registration::Campaign.statuses[:completed])
        # rubocop:enable Rails/SkipsModelValidations
      end

      it "returns :conducted" do
        expect(exam.status_phase).to eq(:conducted)
      end
    end

    context "without a campaign (skip_campaigns)" do
      let(:exam) do
        create(:exam,
               date: 2.weeks.from_now,
               lecture: lecture,
               skip_campaigns: true)
      end

      it "returns :finalized when date is in the future" do
        expect(exam.status_phase).to eq(:finalized)
      end

      it "returns :conducted when date is in the past" do
        # rubocop:disable Rails/SkipsModelValidations
        exam.update_column(:date, 1.week.ago)
        # rubocop:enable Rails/SkipsModelValidations
        expect(exam.status_phase).to eq(:conducted)
      end
    end
  end

  describe "#materialize_allocation!" do
    let(:lecture) { create(:lecture) }
    let(:exam) { create(:exam, lecture: lecture) }
    let(:campaign) { create(:registration_campaign) }
    let(:user1) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }

    it "propagates users to the lecture roster" do
      expect(lecture.lecture_memberships.where(user: [user1, user2])).to be_empty

      exam.materialize_allocation!(user_ids: [user1.id, user2.id], campaign: campaign)

      expect(lecture.lecture_memberships.where(user: user1)).to exist
      expect(lecture.lecture_memberships.where(user: user2)).to exist
    end

    it "adds new users to the exam roster" do
      exam.materialize_allocation!(user_ids: [user1.id, user2.id], campaign: campaign)

      expect(exam.allocated_user_ids).to include(user1.id, user2.id)
    end

    it "removes users not in the target list" do
      create(:exam_roster_entry,
             exam: exam,
             user: user1,
             source_campaign: campaign)

      exam.materialize_allocation!(user_ids: [user2.id], campaign: campaign)

      expect(exam.allocated_user_ids).not_to include(user1.id)
      expect(exam.allocated_user_ids).to include(user2.id)
    end

    it "preserves manually added users" do
      manual_user = create(:confirmed_user)
      create(:exam_roster_entry,
             exam: exam,
             user: manual_user,
             source_campaign: nil)

      exam.materialize_allocation!(user_ids: [user1.id], campaign: campaign)

      expect(exam.allocated_user_ids).to include(manual_user.id, user1.id)
    end
  end

  describe "auto-campaign creation" do
    context "when registration_campaigns flag is enabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?)
          .with(:registration_campaigns).and_return(true)
      end

      it "creates a campaign and registration item" do
        exam = create(:exam, :with_date)

        campaign = exam.registration_campaign
        expect(campaign).to be_present
        expect(campaign).to be_draft
        expect(campaign).to be_first_come_first_served
        expect(campaign.campaignable).to eq(exam.lecture)
      end

      it "sets deadline from registration_deadline attr" do
        deadline = 2.weeks.from_now
        exam = create(:exam, registration_deadline: deadline)

        expect(exam.registration_campaign.registration_deadline)
          .to be_within(1.second).of(deadline)
      end

      it "falls back to 3 days before exam date for deadline" do
        exam = create(:exam, :with_date)

        expect(exam.registration_campaign.registration_deadline)
          .to be_within(1.second).of(exam.date - 3.days)
      end

      it "creates a registration item linked to the exam" do
        exam = create(:exam)
        item = Registration::Item.find_by(registerable: exam)

        expect(item).to be_present
        expect(item.registration_campaign).to eq(exam.registration_campaign)
      end

      it "sets item capacity from exam capacity" do
        exam = create(:exam, :with_capacity)

        expect(Registration::Item.find_by(registerable: exam).capacity)
          .to eq(exam.capacity)
      end

      it "does not create campaign when skip_campaigns is true" do
        exam = create(:exam, skip_campaigns: true)

        expect(exam.registration_campaign).to be_nil
        expect(Registration::Item.where(registerable: exam)).not_to exist
      end
    end

    context "when registration_campaigns flag is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?)
          .with(:registration_campaigns).and_return(false)
      end

      it "does not create a campaign" do
        expect(create(:exam).registration_campaign).to be_nil
      end
    end
  end

  describe "destructibility" do
    let(:lecture) { create(:lecture) }
    let(:exam) { create(:exam, lecture: lecture) }

    context "when exam has no roster entries and is not in a campaign" do
      it "is destructible" do
        expect(exam.destructible?).to be(true)
      end

      it "returns nil for non_destructible_reason" do
        expect(exam.non_destructible_reason).to be_nil
      end
    end

    context "when exam has roster entries" do
      before do
        create(:exam_roster_entry, exam: exam, user: create(:confirmed_user))
      end

      it "is not destructible" do
        expect(exam.destructible?).to be(false)
      end

      it "returns :roster_not_empty as non_destructible_reason" do
        expect(exam.non_destructible_reason).to eq(:roster_not_empty)
      end
    end

    context "when exam is part of a draft campaign" do
      before do
        campaign = create(:registration_campaign, status: :draft)
        create(:registration_item,
               registerable: exam,
               registration_campaign: campaign)
      end

      it "is destructible" do
        expect(exam.destructible?).to be(true)
      end

      it "returns nil for non_destructible_reason" do
        expect(exam.non_destructible_reason).to be_nil
      end

      it "#in_campaign? returns true" do
        expect(exam.in_campaign?).to be(true)
      end
    end

    context "when exam is part of an open campaign" do
      before do
        campaign = create(:registration_campaign, campaignable: exam.lecture)
        create(:registration_item,
               registerable: exam,
               registration_campaign: campaign)
        campaign.update!(status: :open)
      end

      it "is not destructible" do
        expect(exam.destructible?).to be(false)
      end

      it "returns :in_campaign as non_destructible_reason" do
        expect(exam.non_destructible_reason).to eq(:in_campaign)
      end
    end

    context "when exam is part of a completed campaign" do
      before do
        campaign = create(:registration_campaign,
                          campaignable: exam.lecture,
                          registration_deadline: 2.weeks.from_now)
        create(:registration_item,
               registerable: exam,
               registration_campaign: campaign)
        # rubocop:disable Rails/SkipsModelValidations
        campaign.update_column(:status, Registration::Campaign.statuses[:completed])
        # rubocop:enable Rails/SkipsModelValidations
      end

      it "is not destructible" do
        expect(exam.destructible?).to be(false)
      end

      it "returns :in_campaign as non_destructible_reason" do
        expect(exam.non_destructible_reason).to eq(:in_campaign)
      end
    end

    context "when exam has both roster entries and is in a campaign" do
      before do
        create(:exam_roster_entry, exam: exam, user: create(:confirmed_user))
        create(:registration_item,
               registerable: exam,
               registration_campaign: create(:registration_campaign))
      end

      it "is not destructible" do
        expect(exam.destructible?).to be(false)
      end

      it "returns :roster_not_empty as first non_destructible_reason" do
        expect(exam.non_destructible_reason).to eq(:roster_not_empty)
      end
    end
  end

  describe "destroy with draft campaign" do
    let(:lecture) { create(:lecture) }

    before do
      allow(Flipper).to receive(:enabled?).and_call_original
      allow(Flipper).to receive(:enabled?)
        .with(:registration_campaigns).and_return(true)
    end

    context "when auto-created campaign is still draft" do
      let(:exam) { create(:exam, :with_date, lecture: lecture) }

      it "destroys the exam" do
        expect { exam.destroy! }.not_to raise_error
      end

      it "destroys even after destructible? memoizes in_campaign?" do
        expect(exam.destructible?).to be(true)

        expect { exam.destroy! }.not_to raise_error
        expect(Exam.find_by(id: exam.id)).to be_nil
      end

      it "destroys the draft campaign" do
        campaign = exam.registration_campaign

        exam.destroy!

        expect(Registration::Campaign.find_by(id: campaign.id)).to be_nil
      end

      it "destroys associated registration items" do
        item = Registration::Item.find_by(registerable: exam)

        exam.destroy!

        expect(Registration::Item.find_by(id: item.id)).to be_nil
      end
    end

    context "when campaign has been opened" do
      let(:exam) { create(:exam, :with_date, lecture: lecture) }

      before do
        exam.registration_campaign.update!(status: :open)
      end

      it "is not destructible" do
        expect(exam.destructible?).to be(false)
      end

      it "does not destroy the exam" do
        expect(exam.destroy).to be(false)
      end

      it "preserves the campaign" do
        campaign = exam.registration_campaign

        exam.destroy

        expect(Registration::Campaign.find_by(id: campaign.id)).to be_present
      end
    end

    context "when skip_campaigns is true" do
      let(:exam) { create(:exam, lecture: lecture, skip_campaigns: true) }

      it "has no campaign" do
        expect(exam.registration_campaign).to be_nil
      end

      it "destroys normally" do
        expect { exam.destroy! }.not_to raise_error
      end
    end
  end
end
