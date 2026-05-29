require "rails_helper"

RSpec.describe("Roster::SelfMaterializationController", type: :request) do
  let(:user)    { create(:confirmed_user_en) }
  let(:lecture) { create(:lecture) }
  let(:tutorial) do
    create(:tutorial,
           lecture: lecture,
           skip_campaigns: true,
           self_materialization_mode: :add_and_remove)
  end
  let(:camp_tutorial) do
    create(:tutorial,
           lecture: lecture,
           skip_campaigns: false)
  end
  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:item) do
    create(:registration_item,
           registration_campaign: campaign,
           registerable: camp_tutorial)
  end

  before do
    sign_in user
    Flipper.enable(:registration_campaigns)
    Flipper.enable(:roster_maintenance)
  end

  describe "POST /tutorials/:id/roster/self_add" do
    it "adds the user to the tutorial" do
      expect do
        post(self_add_tutorial_path(tutorial), as: :turbo_stream)
      end.to change { tutorial.members.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("roster.messages.user_added",
               user: user.info,
               group: tutorial.title)
      )
    end

    it "sends an email when successfully added" do
      expect do
        post(self_add_tutorial_path(tutorial), as: :turbo_stream)
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to eq(
        I18n.t("roster.mailer.roster_added_to_group_email_subject",
               rosterable_title: tutorial.title)
      )
    end

    it "updates the rosterized entries turbo frame" do
      post self_add_tutorial_path(tutorial), as: :turbo_stream

      expect(response.body).to include('target="student_registration_rosterized_entries"')
    end

    it "updates the self materialization zone turbo frame" do
      post self_add_tutorial_path(tutorial), as: :turbo_stream

      expect(response.body).to include('target="self_materialization_zone"')
    end

    context "when user is already in another tutorial of the same lecture" do
      let(:other_tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :add_and_remove)
      end

      before { create(:tutorial_membership, tutorial: other_tutorial, user: user) }

      it "returns a conflict error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.user_already_in_bundle",
                 user: user.info,
                 group: other_tutorial.title)
        )
      end

      it "does not add the user to the tutorial" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end

      it "does not send an email" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context "when the tutorial is locked" do
      it "returns a locked error flash" do
        post self_add_tutorial_path(camp_tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.item_locked"))
      end

      it "does not add the user" do
        expect do
          post(self_add_tutorial_path(camp_tutorial), as: :turbo_stream)
        end.not_to(change { camp_tutorial.members.count })
      end

      it "does not send an email" do
        expect do
          post(self_add_tutorial_path(camp_tutorial), as: :turbo_stream)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context "when self-add is not allowed" do
      let(:tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :remove_only)
      end

      it "returns a not allowed error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.self_add_not_allowed", type: "Tutorial")
        )
      end

      it "does not add the user" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end

      it "does not send an email" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context "when the tutorial is full" do
      let(:tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :add_and_remove,
                          capacity: 1)
      end

      before do
        other_user = create(:confirmed_user)
        create(:tutorial_membership, tutorial: tutorial, user: other_user)
      end

      it "returns a capacity error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.capacity_exceeded"))
      end

      it "does not add the user" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end

      it "does not send an email" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context "when user is already a member of this tutorial" do
      before { create(:tutorial_membership, tutorial: tutorial, user: user) }

      it "returns success without error" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
      end

      it "does not duplicate the membership" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end
    end

    context "uses user locale (not lecture locale) for response" do
      before { user.update!(locale: :en) }

      it "renders response in user locale" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response.body).to include(
          I18n.t("registration.user_registration.index.confirmed_cases", locale: :en)
        )
      end
    end
  end

  describe "DELETE /tutorials/:id/roster/self_remove" do
    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    it "removes the user from the tutorial" do
      expect do
        delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
      end.to change { tutorial.members.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("roster.messages.user_removed", user: user.info)
      )
    end

    it "sends an email when successfully removed" do
      expect do
        delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to eq(
        I18n.t("roster.mailer.roster_removed_from_group_email_subject",
               rosterable_title: tutorial.title)
      )
    end

    it "updates the rosterized entries turbo frame" do
      delete self_remove_tutorial_path(tutorial), as: :turbo_stream

      expect(response.body).to include('target="student_registration_rosterized_entries"')
    end

    context "when the tutorial is locked" do
      it "returns a locked error flash" do
        delete self_remove_tutorial_path(camp_tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.item_locked"))
      end

      it "does not remove the user" do
        expect do
          delete(self_remove_tutorial_path(camp_tutorial), as: :turbo_stream)
        end.not_to(change { camp_tutorial.members.count })
      end

      it "does not send an email" do
        expect do
          delete(self_remove_tutorial_path(camp_tutorial), as: :turbo_stream)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context "when self-remove is not allowed" do
      let(:tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :add_only)
      end

      it "returns a not allowed error flash" do
        delete self_remove_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.self_remove_not_allowed", type: "Tutorial")
        )
      end

      it "does not remove the user" do
        expect do
          delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end

      it "does not send an email" do
        expect do
          delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end
  end
end
