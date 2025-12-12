require "rails_helper"

RSpec.describe("Registration::Items", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
    Flipper.enable(:registration_campaigns)
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "POST /registration_campaigns/:registration_campaign_id/items" do
    let(:valid_params) do
      {
        registration_item: {
          registerable_id: tutorial.id,
          registerable_type: "Tutorial"
        }
      }
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates a new item" do
        expect do
          post(registration_campaign_items_path(campaign), params: valid_params)
        end.to change(Registration::Item, :count).by(1)

        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
        follow_redirect!
        expect(response.body).to include(I18n.t("registration.item.created"))
      end

      context "when creating a new registerable" do
        let(:new_params) do
          {
            registration_item: {
              new_registerable: "true",
              registerable_type: "Tutorial",
              title: "New Tutorial",
              capacity: 20
            }
          }
        end

        it "creates a new tutorial and item" do
          expect do
            post(registration_campaign_items_path(campaign), params: new_params)
          end.to change(Registration::Item, :count).by(1)
             .and(change(Tutorial, :count).by(1))

          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
          follow_redirect!
          expect(response.body).to include(I18n.t("registration.item.created"))
        end
      end

      context "with invalid parameters" do
        it "does not create an item" do
          expect do
            post(registration_campaign_items_path(campaign), params: {
                   registration_item: { registerable_id: nil }
                 })
          end.not_to change(Registration::Item, :count)

          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post(registration_campaign_items_path(campaign), params: valid_params)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /registration_campaigns/:registration_campaign_id/items/:id" do
    let!(:item) do
      create(:registration_item, registration_campaign: campaign, registerable: tutorial)
    end

    context "as an editor" do
      before { sign_in editor }

      it "updates the item capacity" do
        patch registration_campaign_item_path(campaign, item), params: {
          registration_item: { capacity: 42 }
        }

        expect(item.reload.capacity).to eq(42)
        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
      end

      it "allows setting capacity to unlimited (nil)" do
        patch registration_campaign_item_path(campaign, item), params: {
          registration_item: { capacity: nil }
        }

        expect(item.reload.capacity).to be_nil
        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
      end

      context "when update fails (e.g. capacity too low)" do
        before do
          campaign.update(allocation_mode: :first_come_first_served, status: :open)
          create_list(:registration_user_registration, 5, :confirmed, registration_item: item)
          tutorial.update(capacity: 10)
        end

        it "does not update and shows error" do
          patch registration_campaign_item_path(campaign, item), params: {
            registration_item: { capacity: 2 }
          }

          expect(item.reload.capacity).to eq(10)
          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
          follow_redirect!
          expect(response.body)
            .to include(I18n.t(
                          "activerecord.errors.models.registration/item.attributes.base.capacity_too_low",
                          count: 5
                        ))
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch registration_campaign_item_path(campaign, item), params: {
          registration_item: { capacity: 42 }
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /registration_campaigns/:registration_campaign_id/items/:id" do
    let!(:item) do
      create(:registration_item, registration_campaign: campaign, registerable: tutorial)
    end

    context "as an editor" do
      before { sign_in editor }

      context "when campaign is draft" do
        it "deletes the item" do
          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.to change(Registration::Item, :count).by(-1)

          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
        end

        context "with cascade delete" do
          it "deletes the item and the registerable" do
            expect do
              delete(registration_campaign_item_path(campaign, item), params: { cascade: "true" })
            end.to change(Registration::Item, :count).by(-1)
               .and(change(Tutorial, :count).by(-1))

            expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
          end
        end
      end

      context "when campaign is open" do
        before { campaign.update(status: :open) }

        it "does not delete the item" do
          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.not_to change(Registration::Item, :count)

          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "campaigns"))
          follow_redirect!
          expect(response.body).to include(I18n.t("activerecord.errors.models.registration/item" + ".attributes.base.frozen"))
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        delete registration_campaign_item_path(campaign, item)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
