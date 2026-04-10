require "rails_helper"

RSpec.describe(RegistrationCampaignContext) do
  let(:dummy_class) do
    Class.new do
      include RegistrationCampaignContext

      attr_accessor :params, :current_user

      def t(key, *)
        I18n.t(key, *)
      end
    end
  end

  let(:context_instance) { dummy_class.new }
  let(:lecture) { create(:lecture) }
  let(:registerable) { create(:tutorial, lecture: lecture) }
  let(:error_target) { double("ErrorTarget", errors: ActiveModel::Errors.new(Object.new)) }

  # A user that can create campaigns and items (e.g. editor of the lecture)
  let(:editor) { create(:user) }
  let(:student) { create(:user) }

  before do
    lecture.editors << editor
    context_instance.params = {}
    context_instance.current_user = editor
  end

  describe "#apply_registration_context" do
    context "when registration_section is not 'campaign'" do
      before { context_instance.params[:registration_section] = "something_else" }

      it "returns true immediately and does not create campaign or item" do
        expect(Registration::Campaign.count).to eq(0)
        expect(Registration::Item.count).to eq(0)

        result = context_instance.send(:apply_registration_context,
                                       registerable: registerable,
                                       lecture: lecture,
                                       error_target: error_target)
        expect(result).to be(true)
        expect(Registration::Campaign.count).to eq(0)
        expect(Registration::Item.count).to eq(0)
      end
    end

    context "when registration_section is 'campaign'" do
      before { context_instance.params[:registration_section] = "campaign" }

      context "when no existing campaign is found and one gets newly created" do
        it "creates a new campaign and a registration item" do
          expect do
            result = context_instance.send(:apply_registration_context,
                                           registerable: registerable,
                                           lecture: lecture,
                                           error_target: error_target)
            expect(result).to be(true)
          end.to change(Registration::Campaign, :count).by(1)
             .and(change(Registration::Item, :count).by(1))

          campaign = Registration::Campaign.last
          expect(campaign.campaignable).to eq(lecture)
          expect(campaign.allocation_mode).to eq("first_come_first_served")

          item = Registration::Item.last
          expect(item.registration_campaign).to eq(campaign)
          expect(item.registerable).to eq(registerable)
        end

        it "returns false and adds error if user lacks campaign create permission" do
          context_instance.current_user = student
          result = context_instance.send(:apply_registration_context,
                                         registerable: registerable,
                                         lecture: lecture,
                                         error_target: error_target)

          expect(result).to be(false)
          expect(error_target.errors.full_messages)
            .to include(I18n.t("registration.campaign.create_failed"))
        end

        it "returns false and adds error if campaign save fails" do
          allow_any_instance_of(Registration::Campaign).to receive(:save).and_return(false)
          allow_any_instance_of(Registration::Campaign)
            .to receive_message_chain(:errors,
                                      :full_messages, :to_sentence)
            .and_return("Campaign Save Error")

          result = context_instance.send(:apply_registration_context,
                                         registerable: registerable,
                                         lecture: lecture,
                                         error_target: error_target)

          expect(result).to be(false)
          expect(error_target.errors.full_messages).to include("Campaign Save Error")
        end
      end

      context "when an existing campaign is specified by ID" do
        let!(:existing_campaign) { create(:registration_campaign, campaignable: lecture) }

        before do
          context_instance.params[:registration_campaign_id] = existing_campaign.id.to_s
        end

        it "adds the registration item to the existing campaign" do
          expect do
            result = context_instance.send(:apply_registration_context,
                                           registerable: registerable,
                                           lecture: lecture,
                                           error_target: error_target)
            expect(result).to be(true)
          end.to change(Registration::Item, :count).by(1)
             .and(change(Registration::Campaign, :count).by(0))

          item = Registration::Item.last
          expect(item.registration_campaign).to eq(existing_campaign)
        end

        it "returns false if the specified campaign id is not found" do
          context_instance.params[:registration_campaign_id] = "99999"

          result = context_instance.send(:apply_registration_context,
                                         registerable: registerable,
                                         lecture: lecture,
                                         error_target: error_target)

          expect(result).to be(false)
          expect(error_target.errors.full_messages)
            .to include(I18n.t("registration.campaign.not_found"))
        end
      end

      context "when no ID is provided but a campaign already exists" do
        let!(:existing_campaign) { create(:registration_campaign, campaignable: lecture) }

        it "defaults to using the most recently created campaign" do
          newer_campaign = create(:registration_campaign, campaignable: lecture,
                                                          created_at: 1.day.from_now)

          expect do
            result = context_instance.send(:apply_registration_context,
                                           registerable: registerable,
                                           lecture: lecture,
                                           error_target: error_target)
            expect(result).to be(true)
          end.to change(Registration::Item, :count).by(1)
             .and(change(Registration::Campaign, :count).by(0))

          item = Registration::Item.last
          expect(item.registration_campaign).to eq(newer_campaign)
        end
      end

      context "when failing to create a registration item" do
        it "returns false and adds error if user lacks item create permission" do
          # Mock ability so campaign create passes, but item create fails.
          allow_any_instance_of(RegistrationCampaignAbility).to receive(:can?).and_return(true)
          allow_any_instance_of(RegistrationItemAbility).to receive(:can?).and_return(false)

          result = context_instance.send(:apply_registration_context,
                                         registerable: registerable,
                                         lecture: lecture,
                                         error_target: error_target)

          expect(result).to be(false)
          expect(error_target.errors.full_messages)
            .to include(I18n.t("registration.campaign.create_failed"))
        end

        it "returns false and adds error if item save fails" do
          allow_any_instance_of(Registration::Item).to receive(:save).and_return(false)
          allow_any_instance_of(Registration::Item)
            .to receive_message_chain(:errors,
                                      :full_messages, :to_sentence).and_return("Item Save Error")

          result = context_instance.send(:apply_registration_context,
                                         registerable: registerable,
                                         lecture: lecture,
                                         error_target: error_target)

          expect(result).to be(false)
          expect(error_target.errors.full_messages).to include("Item Save Error")
        end
      end
    end
  end
end
