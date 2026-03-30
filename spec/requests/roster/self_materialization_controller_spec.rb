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

      it "does not send an email" do
        expect do
          post(:self_add, params: params)
        end.not_to(change { ActionMailer::Base.deliveries.count })
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

      it "does not send an email" do
        expect do
          post(:self_add, params: params)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context "when self-add succeeds and should send email" do
      before do
        allow_any_instance_of(Rosters::SelfMaterializationService)
          .to receive(:self_add!)
        allow(RosterMailer).to receive_message_chain(:self_added, :deliver_now)
      end

      it "sends an email" do
        expect do
          post(:self_add, params: params)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
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

      it "does not send an email" do
        expect do
          post(:self_remove, params: params)
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context "when self-remove succeeds and should send email" do
      before do
        allow_any_instance_of(Rosters::SelfMaterializationService)
          .to receive(:self_remove!)
        allow(RosterMailer).to receive_message_chain(:self_removed, :deliver_now)
      end

      it "sends an email" do
        expect do
          post(:self_remove, params: params)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
