require "rails_helper"

RSpec.describe("Roster::SelfMaterializationController", type: :request) do
  let(:user)     { create(:confirmed_user) }
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
  end

  describe "DELETE /tutorials/:id/roster/self_remove" do
    before { allow(service).to receive(:self_remove!) }

    it "calls the service" do
      delete self_remove_tutorial_path(tutorial), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(service).to have_received(:self_remove!)
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
