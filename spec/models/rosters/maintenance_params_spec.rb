require "rails_helper"

RSpec.describe(Rosters::MaintenanceParams) do
  let(:lecture) { create(:lecture) }
  let(:params_hash) { ActionController::Parameters.new(raw_params) }

  describe "#group_type" do
    context "with a single string value" do
      let(:raw_params) { { group_type: "tutorials" } }

      it "returns a symbol" do
        mp = described_class.new(params_hash, lecture: lecture)
        expect(mp.group_type).to eq(:tutorials)
      end
    end

    context "with an array value" do
      let(:raw_params) { { group_type: ["tutorials", "cohorts"] } }

      it "returns an array of symbols" do
        mp = described_class.new(params_hash, lecture: lecture)
        expect(mp.group_type).to eq([:tutorials, :cohorts])
      end
    end

    context "with no value" do
      let(:raw_params) { {} }

      it "defaults to :all" do
        mp = described_class.new(params_hash, lecture: lecture)
        expect(mp.group_type).to eq(:all)
      end
    end
  end

  describe "#source and predicates" do
    context "with valid source 'panel'" do
      let(:raw_params) { { source: "panel" } }

      it "accepts the value" do
        mp = described_class.new(params_hash)
        expect(mp.source).to eq("panel")
        expect(mp).to be_panel
        expect(mp).not_to be_unassigned
        expect(mp).not_to be_participants
      end
    end

    context "with valid source 'unassigned' and source_id" do
      let(:campaign) do
        create(:registration_campaign, :open, campaignable: lecture)
      end
      let(:raw_params) { { source: "unassigned", source_id: campaign.id.to_s } }

      it "accepts the value" do
        mp = described_class.new(params_hash, lecture: lecture)
        expect(mp.source).to eq("unassigned")
        expect(mp).to be_unassigned
      end
    end

    context "with source 'unassigned' but no source_id" do
      let(:raw_params) { { source: "unassigned" } }

      it "is not unassigned" do
        mp = described_class.new(params_hash, lecture: lecture)
        expect(mp.source).to eq("unassigned")
        expect(mp).not_to be_unassigned
      end
    end

    context "with invalid source" do
      let(:raw_params) { { source: "evil_source" } }

      it "rejects the value" do
        mp = described_class.new(params_hash)
        expect(mp.source).to be_nil
      end
    end
  end

  describe "#source_id validation" do
    context "when source_id belongs to a different lecture" do
      let(:other_lecture) { create(:lecture) }
      let(:other_campaign) do
        create(:registration_campaign, :open, campaignable: other_lecture)
      end
      let(:raw_params) { { source: "unassigned", source_id: other_campaign.id.to_s } }

      it "rejects the cross-lecture source_id" do
        mp = described_class.new(params_hash, lecture: lecture)
        expect(mp.source_id).to be_nil
        expect(mp).not_to be_unassigned
      end
    end

    context "when no lecture is provided" do
      let(:raw_params) { { source: "unassigned", source_id: "42" } }

      it "passes through without validation" do
        mp = described_class.new(params_hash)
        expect(mp.source_id).to eq("42")
      end
    end
  end

  describe "#target_type validation" do
    context "with a valid type" do
      let(:raw_params) { { target_type: "Tutorial" } }

      it "accepts the value" do
        mp = described_class.new(params_hash)
        expect(mp.target_type).to eq("Tutorial")
      end
    end

    context "with an invalid type" do
      let(:raw_params) { { target_type: "User" } }

      it "rejects the value" do
        mp = described_class.new(params_hash)
        expect(mp.target_type).to be_nil
      end
    end
  end

  describe "scalar pass-through" do
    let(:raw_params) do
      { user_id: "5", email: "a@b.c", mode: "add_only", search: "foo" }
    end

    it "exposes permitted scalars" do
      mp = described_class.new(params_hash)
      expect(mp.user_id).to eq("5")
      expect(mp.email).to eq("a@b.c")
      expect(mp.mode).to eq("add_only")
      expect(mp.search).to eq("foo")
    end
  end

  describe "unpermitted params" do
    let(:raw_params) { { admin: "true", role: "superuser", source: "panel" } }

    it "does not expose unpermitted keys" do
      mp = described_class.new(params_hash)
      expect(mp).not_to respond_to(:admin)
      expect(mp).not_to respond_to(:role)
      expect(mp.source).to eq("panel")
    end
  end
end
