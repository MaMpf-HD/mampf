require "rails_helper"

RSpec.describe(ParticipationComponent, type: :component) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:course) { create(:course, title: "Linear Algebra") }
  let(:lecture) { create(:lecture, course: course) }
  let(:user) { create(:confirmed_user, email: "student@play") }

  describe "policy rejection messages" do
    it "renders finalization-specific email-policy rejections" do
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Email checked tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :institutional_email,
        :for_finalization,
        registration_campaign: campaign,
        config: { "allowed_domains" => ["example.com"] }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "institutional_email_mismatch"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Email checked tutorial registration")
      expect(rendered.text).to include("Rejected")
      expect(rendered.text).to include(
        "At the time this registration process was finalized"
      )
      expect(rendered.text).to include("required email domains example.com")
      expect(rendered.text).not_to include("Your current email domain is play")
      expect(rendered.css("a")).to be_empty
    end

    it "uses the stored rejection code after the student fixes the policy issue" do
      prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Priority registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "prerequisite_not_met",
        rejection_reason_label: "Prerequisite was missing."
      )
      create(
        :registration_user_registration,
        :confirmed,
        registration_campaign: prerequisite_campaign,
        registration_item: prerequisite_campaign.registration_items.first,
        user: user
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(
        "At the time this registration process was finalized, you did not have a " \
        "confirmed registration in"
      )
      expect(rendered.text).to include("Priority registration")
      expect(rendered.text).not_to include("Your registration was rejected.")
    end

    it "renders the prerequisite campaign label for prerequisite-policy rejections" do
      prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Priority registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "prerequisite_not_met"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(
        "At the time this registration process was finalized, you did not have a " \
        "confirmed registration in"
      )
      expect(rendered.text).to include("Priority registration")
    end

    it "uses the stored policy id when multiple policies share a rejection code" do
      wrong_prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Wrong prerequisite registration",
        items_count: 1
      )
      correct_prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Correct prerequisite registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => wrong_prerequisite_campaign.id }
      )
      correct_policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => correct_prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: correct_policy,
        rejection_reason_code: "prerequisite_not_met"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Correct prerequisite registration")
      expect(rendered.text).not_to include("Wrong prerequisite registration")
    end
  end

  describe "standings before the allocation" do
    it "shows saved preferences as waiting for the allocation" do
      campaign = create(:registration_campaign, :preference_based, :open,
                        campaignable: lecture, items_count: 2)
      first, second = campaign.registration_items.order(:id).to_a
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: second, user: user,
                                              preference_rank: 1)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: first, user: user,
                                              preference_rank: 2)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
      expect(rendered.text.squish)
        .to include("1st #{second.title} · 2nd #{first.title}")
      expect(rendered.css("a[href='##{ActionView::RecordIdentifier
                                       .dom_id(campaign, :student_registration)}']"))
        .to be_present
    end

    it "keeps the preferences once the deadline has passed" do
      campaign = create(:registration_campaign, :preference_based, :closed,
                        campaignable: lecture, items_count: 1)
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first,
             user: user, preference_rank: 1)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
      expect(rendered.css("a")).to be_empty
    end

    it "says that a first come, first served place is checked again" do
      campaign = create(:registration_campaign, :first_come_first_served, :open,
                        campaignable: lecture, items_count: 1)
      item = campaign.registration_items.first
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, registration_item: item, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(item.registerable.title)
      expect(rendered.text).to include("Registered")
      expect(rendered.text)
        .to include("The requirements are checked again when the process is finalized.")
    end
  end

  describe "outcomes" do
    it "shows a capacity rejection with the preferences that could not be met" do
      campaign = create(:registration_campaign, :preference_based, :with_items,
                        campaignable: lecture, items_count: 1,
                        description: "Tutorial allocation")
      campaign.update!(status: :completed)
      item = campaign.registration_items.first
      create(:registration_user_registration, :capacity_rejected,
             registration_campaign: campaign, registration_item: item,
             user: user, preference_rank: 1)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tutorial allocation")
      expect(rendered.text).to include("No place")
      expect(rendered.text).to include("Your preferences: 1st #{item.title}")
    end

    it "shows the tutorial a student was assigned to" do
      tutorial = create(:tutorial, lecture: lecture, title: "Tutorial 4")
      create(:tutorial_membership, tutorial: tutorial, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tutorial 4")
      expect(rendered.text).to include("Assigned")
    end

    it "says when a student was taken off an exam list" do
      exam = create(:exam, lecture: lecture)
      create(:exam_roster_entry, exam: exam, user: user, excluded_at: Time.current)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Removed from the exam list")
    end

    it "renders nothing without any standing" do
      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to be_blank
    end
  end
end
