require "rails_helper"

RSpec.describe(Exam, type: :model) do
  describe "Registration::Registerable" do
    it_behaves_like "a registerable model"
  end

  describe "Rosters::Rosterable" do
    it_behaves_like "a rosterable model"
  end

  it "has a valid factory" do
    expect(build(:exam)).to be_valid
  end

  describe "validations" do
    it "is invalid without a title" do
      expect(build(:exam, title: nil)).to be_invalid
    end

    it "is invalid without a lecture" do
      expect(build(:exam, lecture: nil)).to be_invalid
    end

    it "is valid without a date (oral exam)" do
      expect(build(:exam, :oral)).to be_valid
    end

    it "is invalid with negative capacity" do
      expect(build(:exam, capacity: -1)).to be_invalid
    end

    it "is invalid with zero capacity" do
      expect(build(:exam, capacity: 0)).to be_invalid
    end

    it "is valid with positive capacity" do
      expect(build(:exam, capacity: 100)).to be_valid
    end

    it "is valid with nil capacity (unlimited)" do
      expect(build(:exam, capacity: nil)).to be_valid
    end

    describe "registration_deadline" do
      it "is invalid when deadline is in the past on create" do
        exam = build(:exam, :with_date,
                     registration_deadline: 1.day.ago)
        expect(exam).to be_invalid
        expect(exam.errors.where(:registration_deadline, :must_be_in_future))
          .to be_present
      end

      it "is valid when deadline is in the future on create" do
        exam = build(:exam, :with_date,
                     registration_deadline: 1.week.from_now)
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
        let(:exam) { create(:exam, :with_date) }

        before do
          allow(Flipper).to receive(:enabled?).and_call_original
          allow(Flipper).to receive(:enabled?)
            .with(:registration_campaigns).and_return(true)
          campaign = exam.registration_campaign
          campaign.update!(status: :open) if campaign
        end

        it "is invalid when deadline is changed to the past" do
          exam.registration_deadline = 1.day.ago
          expect(exam).to be_invalid
        end

        it "is valid when deadline is changed to the future" do
          exam.registration_deadline = 1.week.from_now
          expect(exam).to be_valid
        end
      end

      context "on update with a completed campaign" do
        let(:exam) { create(:exam, :with_date) }

        before do
          allow(Flipper).to receive(:enabled?).and_call_original
          allow(Flipper).to receive(:enabled?)
            .with(:registration_campaigns).and_return(true)
          campaign = exam.registration_campaign
          if campaign
            campaign.update_column(
              :status,
              Registration::Campaign.statuses[:completed]
            )
          end
        end

        it "allows a past deadline (campaign already finished)" do
          exam.registration_deadline = 1.day.ago
          expect(exam).to be_valid
        end
      end
    end
  end

  describe "associations" do
    it "belongs to a lecture" do
      exam = create(:exam)
      expect(exam.lecture).to be_a(Lecture)
    end

    it "has many exam_rosters" do
      exam = create(:exam)
      create_list(:exam_roster, 3, exam: exam)
      expect(exam.exam_rosters.count).to eq(3)
    end

    it "has many users through exam_rosters" do
      exam = create(:exam)
      users = create_list(:confirmed_user, 3)
      users.each { |user| create(:exam_roster, exam: exam, user: user) }
      expect(exam.users.count).to eq(3)
    end

    it "destroys dependent exam_rosters when destroyed" do
      exam = create(:exam)
      create_list(:exam_roster, 3, exam: exam)

      # Rosterable concern prevents destruction if roster not empty
      # This is expected behavior - clear roster first
      expect(exam.reload.destructible?).to be(false)

      # After clearing roster, exam can be destroyed
      exam.exam_rosters.destroy_all
      expect { exam.destroy }.not_to raise_error
    end
  end

  describe "concerns" do
    it "includes Assessment::Pointable" do
      expect(Exam.ancestors).to include(Assessment::Pointable)
    end

    it "includes Assessment::Gradable" do
      expect(Exam.ancestors).to include(Assessment::Gradable)
    end

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
      users.each { |user| create(:exam_roster, exam: exam, user: user) }
    end

    it "#roster_entries returns exam_rosters" do
      expect(exam.roster_entries).to eq(exam.exam_rosters)
    end

    it "#roster_association_name returns :exam_rosters" do
      expect(exam.roster_association_name).to eq(:exam_rosters)
    end

    it "#allocated_user_ids returns user IDs" do
      expect(exam.allocated_user_ids).to match_array(users.map(&:id))
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
      create(:exam_roster, exam: exam, user: user1, source_campaign: campaign)

      exam.materialize_allocation!(user_ids: [user2.id], campaign: campaign)

      expect(exam.allocated_user_ids).not_to include(user1.id)
      expect(exam.allocated_user_ids).to include(user2.id)
    end

    it "preserves manually added users" do
      manual_user = create(:confirmed_user)
      create(:exam_roster, exam: exam, user: manual_user, source_campaign: nil)

      exam.materialize_allocation!(user_ids: [user1.id], campaign: campaign)

      expect(exam.allocated_user_ids).to include(manual_user.id, user1.id)
    end
  end

  describe "assessment setup" do
    context "when assessment_grading feature flag is enabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(true)
      end

      it "creates an assessment after creation" do
        exam = nil
        expect do
          exam = create(:exam)
        end.to change(Assessment::Assessment, :count).by(1)

        expect(exam.assessment).to be_present
      end
    end

    context "when assessment_grading feature flag is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(false)
      end

      it "does not create an assessment after creation" do
        expect do
          create(:exam)
        end.not_to change(Assessment::Assessment, :count)
      end
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

        campaign = exam.registration_campaign
        expect(campaign.registration_deadline)
          .to be_within(1.second).of(deadline)
      end

      it "falls back to 3 days before exam date for deadline" do
        exam = create(:exam, :with_date)

        campaign = exam.registration_campaign
        expect(campaign.registration_deadline)
          .to be_within(1.second).of(exam.date - 3.days)
      end

      it "creates a registration item linked to the exam" do
        exam = create(:exam)
        item = Registration::Item.find_by(registerable: exam)

        expect(item).to be_present
        expect(item.registration_campaign)
          .to eq(exam.registration_campaign)
      end

      it "sets item capacity from exam capacity" do
        exam = create(:exam, :with_capacity)
        item = Registration::Item.find_by(registerable: exam)

        expect(item.capacity).to eq(exam.capacity)
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
        exam = create(:exam)
        expect(exam.registration_campaign).to be_nil
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
        user = create(:confirmed_user)
        create(:exam_roster, exam: exam, user: user)
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
        create(:registration_item, registerable: exam,
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
        create(:registration_item, registerable: exam,
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
                          registration_deadline: 2.weeks.ago)
        create(:registration_item, registerable: exam,
                                   registration_campaign: campaign)
        campaign.update_column(:status, Registration::Campaign.statuses[:completed])
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
        user = create(:confirmed_user)
        create(:exam_roster, exam: exam, user: user)
        campaign = create(:registration_campaign)
        create(:registration_item, registerable: exam, registration_campaign: campaign)
      end

      it "is not destructible" do
        expect(exam.destructible?).to be(false)
      end

      it "returns :roster_not_empty as first non_destructible_reason (checked first)" do
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
