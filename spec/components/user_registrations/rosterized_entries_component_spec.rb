require "rails_helper"

RSpec.describe(RosterizedEntriesComponent, type: :component) do
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

      rendered = render_inline(
        described_class.new(rosterized_entries: [], lecture: lecture, user: user)
      )

      expect(rendered.text).to include(
        "Your registration for Email checked tutorial registration was rejected"
      )
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

      rendered = render_inline(
        described_class.new(rosterized_entries: [], lecture: lecture, user: user)
      )

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

      rendered = render_inline(
        described_class.new(rosterized_entries: [], lecture: lecture, user: user)
      )

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

      rendered = render_inline(
        described_class.new(rosterized_entries: [], lecture: lecture, user: user)
      )

      expect(rendered.text).to include("Correct prerequisite registration")
      expect(rendered.text).not_to include("Wrong prerequisite registration")
    end
  end
end
