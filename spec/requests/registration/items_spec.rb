require "rails_helper"

RSpec.describe("Registration::Items", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
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

        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
        follow_redirect!
        expect(response.body).to include(I18n.t("registration.item.created"))
      end

      context "with invalid parameters" do
        it "does not create an item" do
          expect do
            post(registration_campaign_items_path(campaign), params: {
                   registration_item: { registerable_id: nil }
                 })
          end.not_to change(Registration::Item, :count)

          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
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

    context "when campaign does not exist" do
      before { sign_in editor }

      it "redirects to root with error" do
        post(registration_campaign_items_path(registration_campaign_id: -1), params: valid_params)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("registration.campaign.not_found"))
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
        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
      end

      it "allows setting capacity to unlimited (nil)" do
        patch registration_campaign_item_path(campaign, item), params: {
          registration_item: { capacity: nil }
        }

        expect(item.reload.capacity).to be_nil
        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
      end

      context "when update fails (e.g. capacity too low)" do
        before do
          campaign.update(allocation_mode: :first_come_first_served, status: :open)
          create_list(:registration_user_registration, 5, :confirmed,
                      registration_item: item, registration_campaign: campaign)
          tutorial.update(capacity: 10)
        end

        it "does not update and shows error" do
          patch registration_campaign_item_path(campaign, item), params: {
            registration_item: { capacity: 2 }
          }

          expect(item.reload.capacity).to eq(10)
          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
          follow_redirect!
          expect(response.body)
            .to include(I18n.t(
                          "activerecord.errors.models.registration/item" \
                          ".attributes.base.capacity_too_low",
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

    context "when item does not exist" do
      before { sign_in editor }

      it "redirects to campaign items tab with error" do
        patch registration_campaign_item_path(campaign, id: -1), params: {
          registration_item: { capacity: 42 }
        }
        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
        expect(flash[:alert]).to eq(I18n.t("registration.item.not_found"))
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
        it "removes the item but keeps the group" do
          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.to change(Registration::Item, :count).by(-1)

          expect(Tutorial.exists?(tutorial.id)).to be(true)
          expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
          follow_redirect!
          expect(response.body).to include(I18n.t("registration.item.removed_from_campaign"))
        end

        it "hands the group back to manual management" do
          delete(registration_campaign_item_path(campaign, item))

          expect(tutorial.reload.skip_campaigns).to be(true)
        end

        it "reports a group that cannot be saved instead of raising" do
          tutorial.update_columns(title: "") # rubocop:disable Rails/SkipsModelValidations

          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.not_to change(Registration::Item, :count)

          expect(flash[:alert]).to be_present
        end
      end

      context "when campaign is open" do
        let!(:other_item) do
          create(:registration_item, registration_campaign: campaign,
                                     registerable: create(:tutorial, lecture: lecture))
        end

        before { campaign.update!(status: :open) }

        it "removes the item but keeps the group" do
          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.to change(Registration::Item, :count).by(-1)

          expect(Tutorial.exists?(tutorial.id)).to be(true)
        end

        it "does not remove an item students have registered for" do
          create(:registration_user_registration,
                 registration_campaign: campaign, registration_item: item)

          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.not_to change(Registration::Item, :count)

          follow_redirect!
          expect(response.body).to include(I18n.t("activerecord.errors.models.registration/item" \
                                                  ".attributes.base" \
                                                  ".cannot_remove_with_registrations"))
        end

        it "does not remove an item once an allocation has been computed" do
          campaign.update_columns(last_allocation_calculated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.not_to change(Registration::Item, :count)

          follow_redirect!
          expect(response.body).to include(I18n.t("activerecord.errors.models.registration/item" \
                                                  ".attributes.base" \
                                                  ".cannot_remove_after_allocation"))
        end

        it "does not remove the last remaining item" do
          other_item.destroy!

          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.not_to change(Registration::Item, :count)

          follow_redirect!
          expect(response.body).to include(I18n.t("activerecord.errors.models.registration/item" \
                                                  ".attributes.base.cannot_remove_last_item"))
        end
      end

      context "when campaign is completed" do
        before { campaign.update!(status: :completed) }

        it "does not remove the item" do
          expect do
            delete(registration_campaign_item_path(campaign, item))
          end.not_to change(Registration::Item, :count)

          follow_redirect!
          expect(response.body).to include(I18n.t("activerecord.errors.models.registration/item" \
                                                  ".attributes.base.cannot_remove_in_status"))
        end
      end

      context "with turbo stream" do
        it "updates the campaigns container" do
          delete registration_campaign_item_path(campaign, item), as: :turbo_stream
          expect(response.body)
            .to include('turbo-stream action="update" target="campaigns_container"')
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
    context "when item does not exist" do
      before { sign_in editor }

      it "redirects to campaign items tab with error" do
        delete registration_campaign_item_path(campaign, id: -1)
        expect(response).to redirect_to(edit_lecture_path(lecture, tab: "groups"))
        expect(flash[:alert]).to eq(I18n.t("registration.item.not_found"))
      end
    end
  end

  # A talk is listed twice on a seminar's edit page, and this route deletes one
  # of them just as TalksController#destroy does.
  describe "DELETE .../items/:id/with_registerable on a seminar" do
    let(:seminar) { create(:seminar) }
    let(:talk) { create(:talk, lecture: seminar) }
    let(:talk_campaign) { create(:registration_campaign, campaignable: seminar) }
    let!(:talk_item) do
      create(:registration_item, registration_campaign: talk_campaign, registerable: talk)
    end

    before do
      create(:editable_user_join, user: editor, editable: seminar)
      sign_in editor
    end

    it "refreshes the content list along with the tiles" do
      delete(with_registerable_registration_campaign_item_path(talk_campaign, talk_item),
             as: :turbo_stream)

      expect(Talk.exists?(talk.id)).to be(false)
      expect(response.body).to include("lecture-content-card")
    end
  end

  describe "DELETE .../items/:id/with_registerable" do
    let(:delete_path) do
      with_registerable_registration_campaign_item_path(campaign, item)
    end

    context "for a tutorial" do
      let!(:item) do
        create(:registration_item, registration_campaign: campaign, registerable: tutorial)
      end

      before { sign_in editor }

      it "deletes item and tutorial" do
        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(-1)
                                                 .and(change(Tutorial, :count).by(-1))

        follow_redirect!
        expect(response.body).to include(I18n.t("registration.item.destroyed"))
      end

      it "keeps both when the tutorial still has submissions with uploads" do
        create(:valid_submission, :with_manuscript,
               tutorial: tutorial, assignment: create(:assignment, lecture: lecture))

        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(0)
                                                 .and(change(Tutorial, :count).by(0))

        follow_redirect!
        expect(response.body)
          .to include(I18n.t("controllers.tutorials.errors.cannot_delete_with_submissions"))
      end

      it "keeps both when the tutorial still has members" do
        tutorial.add_user_to_roster!(create(:confirmed_user))

        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(0)
                                                 .and(change(Tutorial, :count).by(0))

        follow_redirect!
        expect(response.body).to include(I18n.t("roster.errors.cannot_delete_not_empty"))
      end

      it "updates the campaigns container via turbo stream" do
        delete(delete_path, as: :turbo_stream)

        expect(response.body)
          .to include('turbo-stream action="update" target="campaigns_container"')
      end

      context "as a student" do
        it "redirects to root (unauthorized)" do
          sign_in student
          delete(delete_path)
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context "for a talk" do
      let(:seminar) { create(:lecture, :is_seminar) }
      let(:campaign) { create(:registration_campaign, campaignable: seminar) }
      let(:talk) { create(:talk, lecture: seminar) }
      let!(:item) do
        create(:registration_item, registration_campaign: campaign, registerable: talk)
      end

      before do
        create(:editable_user_join, user: editor, editable: seminar)
        sign_in editor
      end

      it "deletes item and talk" do
        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(-1)
                                                 .and(change(Talk, :count).by(-1))
      end

      it "keeps both when the talk still has media" do
        create(:medium, :with_description, :with_editors, teachable: talk,
                                                          sort: "Lecture")

        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(0)
                                                 .and(change(Talk, :count).by(0))

        follow_redirect!
        expect(response.body).to include(I18n.t("roster.errors.cannot_delete_with_media"))
      end

      it "keeps both when the talk still has speakers" do
        talk.add_user_to_roster!(create(:confirmed_user))

        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(0)
                                                 .and(change(Talk, :count).by(0))
      end
    end

    context "for a cohort" do
      let(:cohort) { create(:cohort, context: lecture) }
      let!(:item) do
        create(:registration_item, registration_campaign: campaign, registerable: cohort)
      end

      before { sign_in editor }

      it "deletes item and cohort" do
        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(-1)
                                                 .and(change(Cohort, :count).by(-1))
      end

      it "keeps both when the cohort still has members" do
        cohort.add_user_to_roster!(create(:confirmed_user))

        expect do
          delete(delete_path)
        end.to change(Registration::Item, :count).by(0)
                                                 .and(change(Cohort, :count).by(0))

        follow_redirect!
        expect(response.body).to include(I18n.t("roster.errors.cannot_delete_not_empty"))
      end
    end
  end
end
