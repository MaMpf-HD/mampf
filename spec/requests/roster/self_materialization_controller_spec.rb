require "rails_helper"

RSpec.describe(Roster::SelfMaterializationController, type: :controller) do
  let(:user) { create(:user) }
  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
    sign_in user
    allow_any_instance_of(LectureAbility).to receive(:can?)
      .with(:self_materialize, lecture).and_return(true)
  end

  describe "POST #self_add" do
    let(:params) do
      {
        type: "Tutorial",
        tutorial_id: tutorial.id,
        format: :turbo_stream
      }
    end

    before do
      allow_any_instance_of(Rosters::SelfMaterializationService)
        .to receive(:self_add!)
    end

    it "calls SelfMaterializationService#self_add!" do
      expect_any_instance_of(Rosters::SelfMaterializationService)
        .to receive(:self_add!)

      post :self_add, params: params
    end

    it "returns turbo_stream success response" do
      post :self_add, params: params

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(flash.now[:notice]).to eq(I18n.t("roster.messages.user_added"))
    end

    context "when service raises RosterLockedError" do
      before do
        allow_any_instance_of(Rosters::SelfMaterializationService)
          .to receive(:self_add!)
          .and_raise(Rosters::SelfMaterializationService::RosterLockedError)
      end

      it "renders turbo_stream error flash" do
        post :self_add, params: params

        expect(flash.now[:alert]).to eq(I18n.t("roster.errors.item_locked"))
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when service raises UserAlreadyInBundleError" do
      let(:group) { create(:tutorial) }

      before do
        error = Rosters::UserAlreadyInBundleError.new(group)
        allow(error).to receive(:conflicting_group).and_return(group)

        allow_any_instance_of(Rosters::SelfMaterializationService)
          .to receive(:self_add!)
          .and_raise(error)
      end

      it "renders correct error message" do
        post :self_add, params: params

        expect(flash.now[:alert]).to eq(
          I18n.t("roster.errors.user_already_in_bundle", group: group.title)
        )
      end
    end
  end

  describe "POST #self_remove" do
    let(:params) do
      {
        type: "Tutorial",
        tutorial_id: tutorial.id,
        format: :turbo_stream
      }
    end

    before do
      allow_any_instance_of(Rosters::SelfMaterializationService)
        .to receive(:self_remove!)
    end

    it "calls SelfMaterializationService#self_remove!" do
      expect_any_instance_of(Rosters::SelfMaterializationService)
        .to receive(:self_remove!)

      post :self_remove, params: params
    end

    it "returns turbo_stream success response" do
      post :self_remove, params: params

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(flash.now[:notice]).to eq(I18n.t("roster.messages.user_removed"))
    end

    context "when service raises SelfRemoveNotAllowedError" do
      before do
        allow_any_instance_of(Rosters::SelfMaterializationService)
          .to receive(:self_remove!)
          .and_raise(Rosters::SelfMaterializationService::SelfRemoveNotAllowedError)
      end

      it "renders turbo_stream error flash" do
        post :self_remove, params: params

        expect(flash.now[:alert]).to eq(
          I18n.t("roster.errors.self_remove_not_allowed", type: "Tutorial")
        )
      end
    end
  end

  describe "set_rosterable" do
    context "when type is invalid" do
      it "redirects with error" do
        post :self_add, params: { type: "InvalidType", id: 1 }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("roster.errors.invalid_type"))
      end
    end

    context "when rosterable does not exist" do
      it "redirects with error" do
        post :self_add, params: { type: "Tutorial", tutorial_id: 999 }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("roster.errors.rosterable_not_found"))
      end
    end
  end

  describe "authorization" do
    before do
      allow_any_instance_of(LectureAbility).to receive(:can?)
        .with(:self_materialize, lecture).and_return(false)
    end

    it "raises CanCan::AccessDenied" do
      expect do
        post(:self_add, params: { type: "Tutorial", tutorial_id: tutorial.id })
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
