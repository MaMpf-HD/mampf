require "rails_helper"

RSpec.describe(RosterizedEntriesComponent, type: :component) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:course) { create(:course, title: "Linear Algebra") }
  let(:lecture) { create(:lecture, course: course) }
  let(:user) { create(:confirmed_user, email: "student@play") }

  describe "policy rejection messages" do
    it "renders the user's current domain and profile link for email-policy rejections" do
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Email checked tutorial registration",
        items_count: 1
      )
      create(
        :registration_policy,
        :institutional_email,
        :for_finalization,
        registration_campaign: campaign,
        config: { "allowed_domains" => ["example.com"] }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY,
        rejection_reason_code: "institutional_email_mismatch"
      )

      rendered = render_inline(
        described_class.new(rosterized_entries: [], lecture: lecture, user: user)
      )

      expect(rendered.text).to include(
        "Your registration for Email checked tutorial registration was rejected"
      )
      expect(rendered.text).to include("Your current email domain is play")
      expect(rendered.text).to include("requires example.com")
      expect(rendered.css("a").pluck("href"))
        .to include("/profile/edit")
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
      create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY,
        rejection_reason_code: "prerequisite_not_met"
      )

      rendered = render_inline(
        described_class.new(rosterized_entries: [], lecture: lecture, user: user)
      )

      expect(rendered.text).to include("You need a confirmed registration in")
      expect(rendered.text).to include("Priority registration")
    end
  end
end
