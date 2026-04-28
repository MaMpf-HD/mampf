require "rails_helper"

RSpec.describe(Registration::StatusEventWriter, type: :model) do
  describe ".call" do
    it "writes one event per registration using a shared correlation id" do
      campaign = FactoryBot.create(:registration_campaign, :preference_based)
      item1 = FactoryBot.create(:registration_item, registration_campaign: campaign)
      item2 = FactoryBot.create(:registration_item, registration_campaign: campaign)
      user1 = FactoryBot.create(:user)
      user2 = FactoryBot.create(:user)
      registration1 = FactoryBot.create(:registration_user_registration,
                                        :preference_based,
                                        registration_campaign: campaign,
                                        registration_item: item1,
                                        user: user1,
                                        preference_rank: 1)
      registration2 = FactoryBot.create(:registration_user_registration,
                                        :preference_based,
                                        registration_campaign: campaign,
                                        registration_item: item2,
                                        user: user2,
                                        preference_rank: 1)
      actor = FactoryBot.create(:confirmed_user)
      correlation_id = SecureRandom.uuid

      events = described_class.call(
        registrations: [registration1, registration2],
        action: Registration::StatusEvent::ACTION_TEACHER_REJECT,
        reason_type: Registration::StatusEvent::REASON_TYPE_MANUAL,
        reason_code: Registration::StatusEvent::REASON_CODE_WITHDRAWN_BY_TEACHER,
        actor: actor,
        correlation_id: correlation_id,
        snapshot: { "label" => "Teacher rejected" }
      )

      expect(events.size).to eq(2)
      expect(events.map(&:registration_id)).to contain_exactly(registration1.id, registration2.id)
      expect(events.map(&:registration_campaign_id).uniq).to eq([campaign.id])
      expect(events.map(&:correlation_id).uniq).to eq([correlation_id])
      expect(events.map(&:actor_id).uniq).to eq([actor.id])
    end

    it "supports snapshot generation per registration" do
      registration = FactoryBot.create(:registration_user_registration)

      event = described_class.call(
        registrations: registration,
        action: Registration::StatusEvent::ACTION_SYSTEM_CONFIRM,
        snapshot: lambda do |reg|
          { "registration_id" => reg.id }
        end
      ).first

      expect(event.snapshot).to eq({ "registration_id" => registration.id })
    end

    it "allows one-off events without a correlation id" do
      registration = FactoryBot.create(:registration_user_registration)

      event = described_class.call(
        registrations: registration,
        action: Registration::StatusEvent::ACTION_TEACHER_REJECT,
        reason_type: Registration::StatusEvent::REASON_TYPE_MANUAL,
        reason_code: Registration::StatusEvent::REASON_CODE_WITHDRAWN_BY_TEACHER,
        correlation_id: nil,
        snapshot: { "label" => "Teacher rejected" }
      ).first

      expect(event).to be_valid
      expect(event.correlation_id).to be_nil
    end
  end
end
