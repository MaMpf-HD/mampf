require "rails_helper"

RSpec.describe(Registration::AllocationMaterializer, type: :model) do
  let(:campaign) { create(:registration_campaign, :with_items, status: :processing) }
  let(:item) { campaign.registration_items.first }
  let(:user) { create(:user) }
  let(:materializer) { described_class.new(campaign) }

  before do
    create(:registration_user_registration, :confirmed, registration_item: item, user: user,
                                                        registration_campaign: campaign)
  end

  describe "#materialize!" do
    it "delegates to registerable#materialize_allocation!" do
      # Mock the chain to return our specific item
      relation = double("ActiveRecord::Relation")
      allow(campaign).to receive(:registration_items).and_return(relation)
      allow(relation).to receive(:includes).with(:registerable).and_return(relation)
      allow(relation).to receive(:find_each).and_yield(item)

      expect(item.registerable).to receive(:materialize_allocation!).with(
        user_ids: [user.id],
        campaign: campaign
      )

      materializer.materialize!
    end

    it "updates the materialized_at timestamp for confirmed registrations" do
      relation = double("ActiveRecord::Relation")
      allow(campaign).to receive(:registration_items).and_return(relation)
      allow(relation).to receive(:includes).with(:registerable).and_return(relation)
      allow(relation).to receive(:find_each).and_yield(item)
      allow(item.registerable).to receive(:materialize_allocation!)

      expect do
        materializer.materialize!
      end.to change {
               user.user_registrations.find_by(registration_item: item)
                   .reload.materialized_at
             }.from(nil)
    end

    it "does not enqueue notifications when a later item's materialization fails" do
      campaign.registration_items.first
      campaign.registration_items.second

      call_count = 0
      allow_any_instance_of(Tutorial).to receive(:materialize_allocation!) do
        call_count += 1
        raise ActiveRecord::Rollback if call_count == 2
      end

      perform_enqueued_jobs do
        expect do
          materializer.materialize!
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    describe "finalization email" do
      it "sends a finalized email for each confirmed user" do
        perform_enqueued_jobs do
          expect do
            materializer.materialize!
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq([user.email])
      end

      it "sends the correct subject" do
        perform_enqueued_jobs { materializer.materialize! }

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(user.locale) do
          I18n.t("roster.mailer.roster_added_to_group_email_subject",
                 rosterable_title: item.registerable.title,
                 lecture_title: item.registerable.lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end

      context "when no users are confirmed for an item" do
        before do
          # rubocop:disable Rails/SkipsModelValidations
          user.user_registrations.update_all(status: :pending)
          # rubocop:enable Rails/SkipsModelValidations
        end

        it "does not send an email for that item" do
          perform_enqueued_jobs do
            expect do
              materializer.materialize!
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end

      context "with multiple confirmed users on the same item" do
        let(:other_user) { create(:user, locale: "en") }

        before do
          create(:registration_user_registration, :confirmed, registration_item: item,
                                                              user: other_user,
                                                              registration_campaign: campaign)
        end

        it "sends one email per user" do
          perform_enqueued_jobs do
            expect do
              materializer.materialize!
            end.to change { ActionMailer::Base.deliveries.count }.by(2)
          end

          recipients = ActionMailer::Base.deliveries.last(2).flat_map(&:to)
          expect(recipients).to contain_exactly(user.email, other_user.email)
        end
      end

      it "does not send emails until after the materializing transaction commits" do
        allow(item.registerable).to receive(:materialize_allocation!).and_raise(ActiveRecord::Rollback)

        expect do
          materializer.materialize!
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end
  end
end
