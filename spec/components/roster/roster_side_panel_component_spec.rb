require "rails_helper"

RSpec.describe(RosterSidePanelComponent, type: :component) do
  let(:tutorial) { build_stubbed(:tutorial) }
  let(:campaign) { nil }
  let(:item) { nil }
  let(:opts) { {} }
  let(:component) do
    described_class.new(
      registerable: tutorial,
      students: [],
      campaign: campaign,
      item: item,
      **opts
    )
  end

  describe "#read_only?" do
    it "defaults to false" do
      expect(component.read_only?).to be(false)
    end

    it "reflects the constructor argument" do
      c = described_class.new(read_only: true)
      expect(c.read_only?).to be(true)
    end
  end

  describe "#unassigned?" do
    it "defaults to false" do
      expect(component.unassigned?).to be(false)
    end

    it "reflects the constructor argument" do
      c = described_class.new(is_unassigned: true)
      expect(c.unassigned?).to be(true)
    end
  end

  describe "#allocated?" do
    it "defaults to false" do
      expect(component.allocated?).to be(false)
    end

    it "reflects the constructor argument" do
      c = described_class.new(allocated: true)
      expect(c.allocated?).to be(true)
    end
  end

  describe "#preference_rank_for" do
    let(:student) { double(id: 42) }
    let(:opts) { { preference_ranks: { 42 => 1 } } }

    it "looks up rank by student id" do
      expect(component.preference_rank_for(student)).to eq(1)
    end

    it "returns nil when student has no rank" do
      expect(component.preference_rank_for(double(id: 99))).to be_nil
    end
  end

  describe "#rank_badge_color" do
    {
      1 => "bg-success",
      2 => "bg-primary",
      3 => "bg-warning text-dark",
      4 => "bg-secondary",
      nil => "bg-secondary"
    }.each do |rank, expected|
      it "returns #{expected} for rank #{rank.inspect}" do
        expect(component.rank_badge_color(rank)).to eq(expected)
      end
    end
  end

  describe "#preference_based_campaign?" do
    it "is falsey without an item" do
      expect(component.preference_based_campaign?).to be_falsey
    end

    it "delegates to the campaign's allocation mode" do
      camp = double(preference_based?: true)
      reg_item = double(registration_campaign: camp)
      c = described_class.new(item: reg_item)
      expect(c.preference_based_campaign?).to be(true)
    end
  end

  describe "#drag_controller?" do
    it "is false when read_only" do
      c = described_class.new(
        registerable: tutorial, read_only: true
      )
      expect(c.drag_controller?).to be(false)
    end

    it "is true when registerable is present and not read_only" do
      expect(component.drag_controller?).to be(true)
    end

    it "is true for draggable unassigned (unassigned + campaign)" do
      c = described_class.new(
        is_unassigned: true, campaign: double(id: 1)
      )
      expect(c.drag_controller?).to be(true)
    end

    it "is false for unassigned without campaign and no registerable" do
      c = described_class.new(is_unassigned: true)
      expect(c.drag_controller?).to be(false)
    end
  end

  describe "#drag_source_type" do
    it "returns 'unassigned' for draggable unassigned" do
      c = described_class.new(
        is_unassigned: true, campaign: double(id: 1)
      )
      expect(c.drag_source_type).to eq("unassigned")
    end

    it "returns downcased class name of registerable" do
      expect(component.drag_source_type).to eq("tutorial")
    end
  end

  describe "#drag_source_id" do
    it "returns campaign id for draggable unassigned" do
      camp = double(id: 7)
      c = described_class.new(
        is_unassigned: true, campaign: camp
      )
      expect(c.drag_source_id).to eq(7)
    end

    it "returns registerable id otherwise" do
      expect(component.drag_source_id).to eq(tutorial.id)
    end
  end

  describe "#show_add_form?" do
    it "is true when registerable present, not read_only, not unassigned" do
      expect(component.show_add_form?).to be(true)
    end

    it "is false when read_only" do
      c = described_class.new(registerable: tutorial, read_only: true)
      expect(c.show_add_form?).to be(false)
    end

    it "is false when unassigned" do
      c = described_class.new(
        registerable: tutorial, is_unassigned: true
      )
      expect(c.show_add_form?).to be(false)
    end

    it "is false without registerable" do
      c = described_class.new
      expect(c.show_add_form?).to be(false)
    end
  end

  describe "#show_remove_button?" do
    it "is true when not read_only and not unassigned" do
      expect(component.show_remove_button?).to be(true)
    end

    it "is false when read_only" do
      c = described_class.new(read_only: true)
      expect(c.show_remove_button?).to be(false)
    end

    it "is false when unassigned" do
      c = described_class.new(is_unassigned: true)
      expect(c.show_remove_button?).to be(false)
    end
  end

  describe "#show_campaign_wishes?" do
    let(:campaign) { double(id: 1) }

    it "is true when unassigned, campaign present, and student has regs" do
      reg = double(registration_campaign_id: 1)
      student = double(user_registrations: [reg])
      c = described_class.new(
        is_unassigned: true, campaign: campaign
      )
      expect(c.show_campaign_wishes?(student)).to be(true)
    end

    it "is false when not unassigned" do
      student = double(user_registrations: [])
      expect(component.show_campaign_wishes?(student)).to be(false)
    end

    it "is false without campaign" do
      student = double(user_registrations: [])
      c = described_class.new(is_unassigned: true)
      expect(c.show_campaign_wishes?(student)).to be(false)
    end

    it "is false when student has no matching registrations" do
      reg = double(registration_campaign_id: 999)
      student = double(user_registrations: [reg])
      c = described_class.new(
        is_unassigned: true, campaign: campaign
      )
      expect(c.show_campaign_wishes?(student)).to be(false)
    end
  end

  describe "#student_display_name" do
    it "prefers name" do
      student = double(name: "Alice", email: "a@b.com")
      expect(component.student_display_name(student)).to eq("Alice")
    end

    it "falls back to tutorial_name" do
      student = double(name: nil, email: "a@b.com")
      allow(student).to receive(:try).with(:tutorial_name)
                                     .and_return("Group A")
      expect(component.student_display_name(student)).to eq("Group A")
    end

    it "falls back to email" do
      student = double(name: nil, email: "a@b.com")
      allow(student).to receive(:try).with(:tutorial_name)
                                     .and_return(nil)
      expect(component.student_display_name(student)).to eq("a@b.com")
    end
  end

  describe "#campaign_wishes" do
    let(:campaign) { double(id: 1) }

    it "joins registerable titles sorted by preference_rank" do
      reg_a = double(
        registration_campaign_id: 1,
        preference_rank: 2,
        registration_item: double(registerable: double(title: "B"))
      )
      reg_b = double(
        registration_campaign_id: 1,
        preference_rank: 1,
        registration_item: double(registerable: double(title: "A"))
      )
      student = double(user_registrations: [reg_a, reg_b])
      c = described_class.new(
        is_unassigned: true, campaign: campaign
      )
      expect(c.campaign_wishes(student)).to eq("A, B")
    end

    it "puts nil ranks last" do
      reg = double(
        registration_campaign_id: 1,
        preference_rank: nil,
        registration_item: double(registerable: double(title: "X"))
      )
      student = double(user_registrations: [reg])
      c = described_class.new(
        is_unassigned: true, campaign: campaign
      )
      expect(c.campaign_wishes(student)).to eq("X")
    end
  end
end
