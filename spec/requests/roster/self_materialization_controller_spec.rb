require "rails_helper"

RSpec.describe("Roster::SelfMaterializationController", type: :request) do
  let(:user)     { create(:confirmed_user_en) }
  let(:lecture)  { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:service)  { instance_double(Rosters::SelfMaterializationService) }

  before do
    sign_in user
    Flipper.enable(:registration_campaigns)
    Flipper.enable(:roster_maintenance)

    allow_any_instance_of(LectureAbility)
      .to receive(:authorize!)
      .and_return(true)

    allow(Rosters::SelfMaterializationService)
      .to receive(:new)
      .with(tutorial, user)
      .and_return(service)
  end

  describe "POST /tutorials/:id/roster/self_add" do
    before { allow(service).to receive(:self_add!) }

    it "calls the service" do
      post self_add_tutorial_path(tutorial), as: :turbo_stream

      expect(service).to have_received(:self_add!)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("roster.messages.user_added",
               user: user.info,
               group: tutorial.title)
      )
    end

    context "when RosterLockedError" do
      before do
        allow(service).to receive(:self_add!)
          .and_raise(Rosters::SelfMaterializationService::RosterLockedError)
      end

      it "returns locked error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.item_locked"))
      end
    end

    context "when RosterFullError" do
      before do
        allow(service).to receive(:self_add!)
          .and_raise(Rosters::SelfMaterializationService::RosterFullError)
      end

      it "returns capacity error flash" do
        post self_add_tutorial_path(tutorial), params: { type: "Tutorial" }, as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.capacity_exceeded"))
      end
    end

    context "when SelfAddNotAllowedError" do
      before do
        allow(service).to receive(:self_add!)
          .and_raise(Rosters::SelfMaterializationService::SelfAddNotAllowedError)
      end

      it "returns not allowed error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.self_add_not_allowed", type: "Tutorial")
        )
      end
    end

    context "when CapacityExceededError" do
      before do
        allow(service).to receive(:self_add!)
          .and_raise(Rosters::MaintenanceService::CapacityExceededError)
      end

      it "returns capacity error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.capacity_exceeded"))
      end
    end

    context "when UserAlreadyInBundleError" do
      let(:conflicting_group) { create(:tutorial, lecture: lecture, title: "Mo 14-16") }

      before do
        allow(service).to receive(:self_add!).and_raise(
          Rosters::UserAlreadyInBundleError.new(conflicting_group)
        )
      end

      it "returns a fully interpolated conflict error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.user_already_in_bundle",
                 user: user.info,
                 group: conflicting_group.title)
        )
      end
    end

    context "when rendering the updated registration page state" do
      let(:tutorial) do
        create(:tutorial,
               lecture: lecture,
               skip_campaigns: true,
               self_materialization_mode: :add_and_remove,
               title: "Ti")
      end

      before do
        allow(lecture).to receive(:locale_with_inheritance).and_return("de")
        allow(Rosters::SelfMaterializationService).to receive(:new).and_call_original
      end

      it "uses the user locale and updates the confirmed registrations section" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("target=\"student_registration_rosterized_entries\"")
        expect(response.body).to include(
          I18n.t("registration.user_registration.index.confirmed_cases", locale: :en)
        )
        expect(response.body).to include(
          I18n.t("registration.user_registration.withdraw", locale: :en)
        )
        expect(response.body).not_to include(
          I18n.t("registration.user_registration.withdraw", locale: :de)
        )
      end
    end
  end

  describe "DELETE /tutorials/:id/roster/self_remove" do
    before { allow(service).to receive(:self_remove!) }

    it "calls the service" do
      delete self_remove_tutorial_path(tutorial), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(service).to have_received(:self_remove!)
      expect(response.body).to include(
        I18n.t("roster.messages.user_removed", user: user.info)
      )
    end

    context "when RosterLockedError" do
      before do
        allow(service).to receive(:self_remove!)
          .and_raise(Rosters::SelfMaterializationService::RosterLockedError)
      end

      it "returns locked error flash" do
        delete self_remove_tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.item_locked"))
      end
    end

    context "when SelfRemoveNotAllowedError" do
      before do
        allow(service).to receive(:self_remove!)
          .and_raise(Rosters::SelfMaterializationService::SelfRemoveNotAllowedError)
      end

      it "returns not allowed error flash" do
        delete self_remove_tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.self_remove_not_allowed", type: "Tutorial")
        )
      end
    end
  end
end
