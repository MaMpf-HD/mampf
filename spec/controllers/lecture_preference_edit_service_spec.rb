require rails_helper

RSpec.describe(Registration::UserRegistration::LecturePreferenceEditService, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }

  describe "edit preference tutorial campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based, :open) }
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }

    it "creates a confirmed registration when validations pass, case no user registration" do
      service = described_class.new(campaign, user, item)

      expect do
        service.register!
      end.to change { Registration::UserRegistration.count }.by(1)

      registration = Registration::UserRegistration.last
      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("confirmed")
    end

    it "creates a confirmed registration when validations pass, " \
       "case has rejected user registration" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item2,
        user: user,
        status: :rejected
      )

      service = described_class.new(campaign, user, item)
      service.register!
      registration = Registration::UserRegistration.last

      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("confirmed")
    end

    it "raises error if campaign is closed" do
      campaign.update!(status: :draft)
      service = described_class.new(campaign, user, item)

      result = service.register!
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.campaign_not_opened"))
    end

    it "raises error if user already registered for another item" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item2,
        user: user,
        status: :confirmed
      )

      service = described_class.new(campaign, user, item)

      result = service.register!
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.already_registered"))
    end

    it "raises error if item has no capacity" do
      item.registerable.update!(capacity: 0)
      service = described_class.new(campaign, user, item)

      result = service.register!
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.no_slots"))
    end
  end
end
