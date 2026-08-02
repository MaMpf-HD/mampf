require "rails_helper"

RSpec.describe(GroupTileComponent, type: :component) do
  let(:tutorial) { build_stubbed(:tutorial, location: "INF 205") }
  let(:item) { nil }
  let(:component) { described_class.new(registerable: tutorial, item: item) }

  describe "#render?" do
    it "is true when registerable is present" do
      expect(component.render?).to be(true)
    end

    it "is false when registerable is nil" do
      c = described_class.new(registerable: nil)
      expect(c.render?).to be(false)
    end
  end

  describe "rendering" do
    it "adds tooltip attributes to student tiles" do
      rendered = render_inline(
        described_class.new(
          registerable: tutorial,
          student_tile: true,
          tile_tooltip_text: "Blocked tooltip"
        )
      )
      tile = rendered.css(".tutorial-gtile--student").first

      expect(tile["title"]).to eq("Blocked tooltip")
      expect(tile["data-bs-toggle"]).to eq("tooltip")
      expect(tile["tabindex"]).to eq("0")
    end
  end

  describe "#dom_target" do
    it "returns registerable when no item" do
      expect(component.dom_target).to eq(tutorial)
    end

    context "with an item" do
      let(:item) { double("item") }

      it "returns the item" do
        expect(component.dom_target).to eq(item)
      end
    end
  end

  describe "#roster_key" do
    it "encodes class name and id" do
      expect(component.roster_key).to eq("Tutorial-#{tutorial.id}")
    end
  end

  describe "#registration_count" do
    it "returns nil without an item" do
      expect(component.registration_count).to be_nil
    end

    context "with a first-come-first-served campaign" do
      let(:campaign) { double(first_come_first_served?: true) }
      let(:regs) { double(count: 5) }
      let(:item) do
        double(registration_campaign: campaign, user_registrations: regs)
      end

      it "counts user_registrations" do
        expect(component.registration_count).to eq(5)
      end
    end

    context "with a preference-based campaign" do
      let(:campaign) { double(first_come_first_served?: false) }
      let(:item) do
        double(registration_campaign: campaign, first_choice_count: 3)
      end

      it "returns first_choice_count" do
        expect(component.registration_count).to eq(3)
      end
    end
  end

  describe "#location_text" do
    it "returns location from registerable" do
      expect(component.location_text).to eq("INF 205")
    end

    it "returns nil when registerable has no location" do
      reg = double("registerable", present?: true)
      allow(reg).to receive(:try).with(:location).and_return(nil)
      c = described_class.new(registerable: reg)
      expect(c.location_text).to be_nil
    end
  end

  describe "#date_text" do
    it "is nil for rosterables without dates (e.g. tutorials)" do
      expect(component.date_text).to be_nil
    end

    context "with a talk that has dates" do
      let(:talk) do
        build_stubbed(:talk, dates: [Time.zone.local(2026, 4, 10),
                                     Time.zone.local(2026, 4, 11)])
      end
      let(:component) { described_class.new(registerable: talk) }

      it "joins the formatted dates" do
        expect(component.date_text).to eq("Apr 10 2026, Apr 11 2026")
      end
    end

    context "with a talk that has no dates" do
      let(:talk) { build_stubbed(:talk, dates: []) }
      let(:component) { described_class.new(registerable: talk) }

      it "is nil" do
        expect(component.date_text).to be_nil
      end
    end
  end

  describe "teacher tile date line" do
    let(:lecture) { create(:seminar) }
    let(:talk) do
      create(:talk, lecture: lecture, dates: [Time.zone.local(2026, 4, 10)])
    end
    let(:item) { create(:registration_item, registerable: talk) }

    it "shows the talk date on the non-student tile" do
      rendered = render_inline(described_class.new(registerable: talk, item: item))
      date_line = rendered.css(".bi-calendar-event").first

      expect(date_line).to be_present
      expect(rendered.to_html).to include("Apr 10 2026")
    end

    it "labels the date for screen readers and hides the icon from them" do
      rendered = render_inline(described_class.new(registerable: talk, item: item))

      expect(rendered.css(".bi-calendar-event").first["aria-hidden"]).to eq("true")
      expect(rendered.css(".visually-hidden").map(&:text))
        .to include("#{I18n.t("basics.date")}:")
    end
  end

  describe "student tile metadata rows" do
    let(:tutorial) { build_stubbed(:tutorial, location: "INF 205") }
    let(:rows) do
      [{ label: "Date", value: "Jul 11 2026", icon: "bi-calendar-event" }]
    end

    it "labels the value for screen readers and hides the icon from them" do
      rendered = render_inline(
        described_class.new(registerable: tutorial, student_tile: true,
                            tile_metadata_rows: rows)
      )
      row = rendered.css(".student-registration-tile-meta > div").first

      expect(row.css("i").first["aria-hidden"]).to eq("true")
      expect(row.css(".visually-hidden").text).to eq("Date:")
      expect(row["title"]).to eq("Date")
    end
  end

  describe "#sm_mode" do
    it "returns the mode from registerable" do
      tutorial.self_materialization_mode = "add_only"
      expect(component.sm_mode).to eq("add_only")
    end

    it "falls back to disabled when registerable does not respond" do
      reg = double("registerable", present?: true)
      allow(reg).to receive(:try)
        .with(:self_materialization_mode).and_return(nil)
      c = described_class.new(registerable: reg)
      expect(c.sm_mode).to eq("disabled")
    end
  end

  describe "#sm_active?" do
    it "is false when mode is disabled" do
      expect(component.sm_active?).to be(false)
    end

    it "is true when mode is not disabled" do
      tutorial.self_materialization_mode = "add_only"
      expect(component.sm_active?).to be(true)
    end
  end

  describe "#gtile_type_class" do
    context "with an item" do
      let(:item) { double("item") }

      it { expect(component.gtile_type_class).to eq("tutorial-gtile--campaign") }
    end

    context "with self-enrollment active" do
      before { tutorial.self_materialization_mode = "add_only" }

      it do
        expect(component.gtile_type_class)
          .to eq("tutorial-gtile--self-enrollment")
      end
    end

    it "returns free class by default" do
      expect(component.gtile_type_class).to eq("tutorial-gtile--free")
    end
  end

  describe "#top_bar_class" do
    context "with an item" do
      let(:item) { double("item") }

      it do
        expect(component.top_bar_class)
          .to eq("tutorial-gtile-top-bar--campaign")
      end
    end

    context "with self-enrollment active" do
      before { tutorial.self_materialization_mode = "add_only" }

      it do
        expect(component.top_bar_class)
          .to eq("tutorial-gtile-top-bar--self-enrollment")
      end
    end

    it "returns free class by default" do
      expect(component.top_bar_class).to eq("tutorial-gtile-top-bar--free")
    end
  end

  describe "top-bar tooltip" do
    def bar_title(instance)
      render_inline(instance).css("[data-testid='group-tile-top-bar']").first["title"]
    end

    context "with an item" do
      let(:lecture) { create(:lecture) }
      let(:campaign) do
        create(:registration_campaign, :first_come_first_served, :with_items,
               campaignable: lecture, items_count: 1)
      end
      let(:campaign_item) { campaign.registration_items.first }

      it "describes the registration process" do
        instance = described_class.new(registerable: campaign_item.registerable,
                                       item: campaign_item)
        expect(bar_title(instance))
          .to eq(I18n.t("roster.tooltips.top_bar_campaign"))
      end
    end

    context "with self-enrollment active" do
      before { tutorial.self_materialization_mode = "add_only" }

      it "mirrors the self-enrollment icon tooltip" do
        title = bar_title(described_class.new(registerable: tutorial))
        expect(title).to include(I18n.t("roster.self_materialization.label"))
        expect(title).to include(I18n.t("roster.self_materialization.modes.add_only"))
      end
    end

    it "reports self-enrollment disabled by default" do
      title = bar_title(described_class.new(registerable: tutorial))
      expect(title).to include(I18n.t("roster.self_materialization.modes.disabled"))
    end
  end

  describe "#cohort_without_enrollment?" do
    it "is false for a non-cohort" do
      expect(component.cohort_without_enrollment?).to be(false)
    end

    context "with a cohort that does not propagate" do
      let(:tutorial) { build_stubbed(:cohort, propagate_to_lecture: false) }

      it { expect(component.cohort_without_enrollment?).to be(true) }
    end

    context "with a cohort that propagates" do
      let(:tutorial) { build_stubbed(:cohort, :enrollment) }

      it { expect(component.cohort_without_enrollment?).to be(false) }
    end
  end

  describe "#show_self_enrollment_dropdown?" do
    it "is false when item is present" do
      c = described_class.new(registerable: tutorial,
                              item: double("item"))
      expect(c.show_self_enrollment_dropdown?).to be(false)
    end

    it "is false when registerable has no skip_campaigns" do
      reg = double("registerable", present?: true)
      allow(reg).to receive(:respond_to?).and_return(false)
      c = described_class.new(registerable: reg)
      expect(c.show_self_enrollment_dropdown?).to be(false)
    end

    it "is false when registerable is locked" do
      allow(tutorial).to receive(:locked?).and_return(true)
      expect(component.show_self_enrollment_dropdown?).to be(false)
    end

    it "is true when no item, responds to skip_campaigns, and unlocked" do
      allow(tutorial).to receive(:locked?).and_return(false)
      expect(component.show_self_enrollment_dropdown?).to be(true)
    end
  end

  describe "#sm_icon_for" do
    {
      "add_only" => "bi-box-arrow-in-right",
      "remove_only" => "bi-box-arrow-right",
      "add_and_remove" => "bi-arrow-left-right",
      "disabled" => "bi-person-slash"
    }.each do |mode, expected|
      it "returns #{expected} for #{mode}" do
        expect(component.sm_icon_for(mode)).to eq(expected)
      end
    end
  end

  describe "#sm_icon_class" do
    it "delegates to sm_icon_for with current mode" do
      tutorial.self_materialization_mode = "remove_only"
      expect(component.sm_icon_class).to eq("bi-box-arrow-right")
    end
  end

  describe "#sm_button_class" do
    it "returns text-muted when inactive" do
      expect(component.sm_button_class).to eq("text-muted")
    end

    it "returns text-success when active" do
      tutorial.self_materialization_mode = "add_only"
      expect(component.sm_button_class).to eq("text-success")
    end
  end

  describe "#sm_modes" do
    it "returns all enum keys" do
      expect(component.sm_modes).to match_array(
        ["disabled", "add_only", "remove_only", "add_and_remove"]
      )
    end
  end

  describe "#delete_disabled?" do
    context "without an item (no-campaign group)" do
      it "is false when registerable is destructible" do
        allow(tutorial).to receive(:destructible?).and_return(true)
        expect(component.delete_disabled?).to be(false)
      end

      it "is true when registerable is not destructible" do
        allow(tutorial).to receive(:destructible?).and_return(false)
        expect(component.delete_disabled?).to be(true)
      end
    end

    context "with a campaign item" do
      let(:campaign) { double("campaign") }
      let(:item) { double("item", registration_campaign: campaign) }

      it "is false when campaign is draft" do
        allow(campaign).to receive(:draft?).and_return(true)
        expect(component.delete_disabled?).to be(false)
      end

      it "is true when campaign is not draft" do
        allow(campaign).to receive(:draft?).and_return(false)
        expect(component.delete_disabled?).to be(true)
      end
    end
  end
end
