require "rails_helper"

RSpec.describe(RosterSidePanelComponent, type: :component) do
  let(:tutorial) { build_stubbed(:tutorial) }
  before do
    allow_any_instance_of(described_class).to receive(:t) do |_, key, **opts|
      I18n.t(key, **opts)
    end
  end
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
  describe "#allocated_choice_pills" do
    it "returns empty array if not allocated or no ranks" do
      c1 = described_class.new(allocated: false, preference_ranks: { 1 => 1 })
      c2 = described_class.new(allocated: true, preference_ranks: {})
      expect(c1.allocated_choice_pills).to eq([])
      expect(c2.allocated_choice_pills).to eq([])
    end

    it "aggregates the ranks up to 3 correctly, counts >3 as Other, and nil as Assigned" do
      c = described_class.new(allocated: true,
                              preference_ranks: { 10 => 1, 11 => 1,
                                                  20 => 2, 30 => 3, 40 => 4, 41 => 5, 50 => nil })
      expect(c.allocated_choice_pills)
        .to match_array([
                          { count: 2,
                            label: I18n.t("registration.allocation.stats.rank_label", rank: 1),
                            color: "bg-success" },
                          { count: 1,
                            label: I18n.t("registration.allocation.stats.rank_label", rank: 2),
                            color: "bg-primary" },
                          { count: 1,
                            label: I18n.t("registration.allocation.stats.rank_label", rank: 3),
                            color: "bg-warning text-dark" },
                          { count: 2,
                            label: I18n.t("registration.item.badge.other_choices",
                                          default: "Other"),
                            color: "bg-secondary" },
                          { count: 1,
                            label: I18n.t("registration.allocation.stats.forced_short",
                                          default: "Assigned"), color: "bg-secondary" }
                        ])
    end
  end

  describe "#panel_title" do
    it "returns candidates title when unassigned" do
      expect(described_class.new(is_unassigned: true).panel_title)
        .to eq(I18n.t("roster.candidates.title"))
    end

    it "returns allocated title when allocated" do
      expect(described_class.new(allocated: true).panel_title)
        .to eq(I18n.t(
                 "registration.user_registration.index.allocated_title",
                 default: "Allocated Students"
               ))
    end

    it "returns 1st choice title when readonly and preference_based" do
      camp = double("Campaign", preference_based?: true)
      item_mock = double("Item", registration_campaign: camp)
      expect(described_class.new(read_only: true,
                                 item: item_mock).panel_title)
        .to eq(I18n.t(
                 "registration.user_registration.index.first_choice_title",
                 default: "1st Choice Registrations"
               ))
    end

    it "returns registrations title when readonly without preference" do
      expect(described_class.new(read_only: true).panel_title)
        .to eq(I18n.t(
                 "registration.user_registration.index.title", default: "Registrations"
               ))
    end

    it "returns default participants title fallback" do
      expect(described_class.new.panel_title).to eq(I18n.t("roster.details.participants"))
    end
  end

  describe "#further_choice_summary" do
    it "returns nil if not preference_based_campaign?" do
      expect(described_class.new.further_choice_summary).to be_nil
    end

    it "formats string for further choices correctly" do
      camp = double("Campaign", preference_based?: true)

      mock_group = double("group")
      allow(mock_group).to receive(:count).and_return({ 2 => 5, 3 => 2, 4 => 1, 5 => 3 })
      mock_where = double("where")
      allow(mock_where).to receive(:group).with(:preference_rank).and_return(mock_group)
      mock_assoc = double("user_registrations")
      allow(mock_assoc).to receive(:where).with("preference_rank >= 2").and_return(mock_where)

      item_mock = double("Item", registration_campaign: camp, user_registrations: mock_assoc)
      c = described_class.new(item: item_mock)

      second = "5 #{I18n.t("registration.item.badge.second_choice")}"
      third = "2 #{I18n.t("registration.item.badge.third_choice")}"
      other = "4 #{I18n.t("registration.item.badge.other_choices")}"

      expect(c.further_choice_summary).to eq("#{second}, #{third}, #{other}")
    end
  end

  describe "#tutors_text" do
    it "returns nil without registerable" do
      expect(described_class.new.tutors_text).to be_nil
    end

    it "delegates to helpers with registerable" do
      c = described_class.new(registerable: tutorial)
      allow(c).to receive(:helpers).and_return(double(roster_tutors_text: "Tutor A"))
      expect(c.tutors_text).to eq("Tutor A")
    end
  end

  describe "#add_member_path" do
    it "returns nil without registerable" do
      expect(described_class.new.add_member_path).to be_nil
    end

    it "delegates to helpers with registerable" do
      c = described_class.new(registerable: tutorial)
      allow(c).to receive(:helpers).and_return(double(roster_add_member_path: "/path"))
      expect(c.add_member_path).to eq("/path")
    end
  end

  describe "#move_member_path_template" do
    it "returns nil without registerable" do
      expect(described_class.new.move_member_path_template).to be_nil
    end

    it "delegates to helpers with registerable" do
      c = described_class.new(registerable: tutorial)
      allow(c).to receive(:helpers).and_return(double(roster_move_member_path_template: "/move"))
      expect(c.move_member_path_template).to eq("/move")
    end
  end

  describe "#remove_member_path" do
    it "returns nil without registerable" do
      expect(described_class.new.remove_member_path(double)).to be_nil
    end

    it "delegates to helpers with registerable" do
      c = described_class.new(registerable: tutorial)
      allow(c).to receive(:helpers).and_return(double(roster_remove_member_path: "/remove"))
      expect(c.remove_member_path(double("student"))).to eq("/remove")
    end
  end

  describe "static text methods" do
    it "returns overbooking_warning" do
      expect(described_class.new.overbooking_warning)
        .to eq(I18n.t("roster.warnings.confirm_overbooking"))
    end

    it "returns empty_state_text" do
      expect(described_class.new.empty_state_text).to eq(I18n.t("roster.details.select_group"))
    end
  end
  describe "additional branch coverage" do
    it "campaign_wishes handles nil preference_rank" do
      reg_nil = double(
        registration_campaign_id: 1,
        preference_rank: nil,
        registration_item: double(registerable: double(title: "Default"))
      )
      reg1 = double(
        registration_campaign_id: 1,
        preference_rank: 1,
        registration_item: double(registerable: double(title: "First"))
      )
      student = double(user_registrations: [reg_nil, reg1])
      c = described_class.new(campaign: double(id: 1))
      expect(c.campaign_wishes(student)).to eq("First, Default")
    end

    it "relevant_registrations handles non-matching campaigns" do
      reg = double(registration_campaign_id: 2)
      student = double(user_registrations: [reg])
      c = described_class.new(is_unassigned: true, campaign: double(id: 1))
      expect(c.show_campaign_wishes?(student)).to be(false)
    end

    it "allocated_choice_pills skips missing tanks and zero counts" do
      c = described_class.new(allocated: true, preference_ranks: { 10 => 1 })
      pills = c.allocated_choice_pills
      expect(pills.length).to eq(1)
      expect(pills.first[:count]).to eq(1)
      expect(pills.first[:label]).to include("1")
    end

    it "further_choice_summary skips when counts are empty" do
      camp = double("Campaign", preference_based?: true)
      mock_group = double("group")
      allow(mock_group).to receive(:count).and_return({})
      mock_where = double("where")
      allow(mock_where).to receive(:group).with(:preference_rank).and_return(mock_group)
      mock_assoc = double("user_registrations")
      allow(mock_assoc).to receive(:where).with("preference_rank >= 2").and_return(mock_where)

      item_mock = double("Item", registration_campaign: camp, user_registrations: mock_assoc)
      c = described_class.new(item: item_mock)
      expect(c.further_choice_summary).to eq("")
    end

    it "student_display_name handles empty string fallbacks" do
      student = double(name: "", email: "a@b.com")
      allow(student).to receive(:try).with(:tutorial_name).and_return("")
      c = described_class.new
      expect(c.student_display_name(student)).to eq("a@b.com")
    end
  end
  describe "more safe navigation branches" do
    it "preference_based_campaign? handles item with no registration_campaign" do
      c = described_class.new(item: double("Item", registration_campaign: nil))
      expect(c.preference_based_campaign?).to be_nil
    end
  end
end
