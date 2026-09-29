require "rails_helper"

RSpec.describe(GroupRowComponent, type: :component) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

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

  describe "the count" do
    def fcfs_item(confirmed)
      campaign = double(first_come_first_served?: true)
      double("item", registration_campaign: campaign, confirmed_registrations_count: confirmed)
    end

    def preference_item(first_choices)
      campaign = double(first_come_first_served?: false)
      double("item", registration_campaign: campaign, first_choice_count: first_choices)
    end

    def component_for(capacity:, item: nil, roster: 0)
      tutorial.capacity = capacity
      allow(tutorial).to receive(:roster_entries).and_return(double(count: roster))
      described_class.new(registerable: tutorial, item: item)
    end

    it "counts the confirmed registrations of a first come, first served campaign" do
      c = component_for(capacity: 12, item: fcfs_item(12))

      expect(c.count_text).to eq("12 / 12 confirmed")
      expect(c.count_state).to eq([:full, "Full"])
      expect(c.bar?).to be(true)
    end

    it "counts first choices as demand, without a bar" do
      c = component_for(capacity: 1, item: preference_item(3))

      expect(c.count_text).to eq("3 first choices · 1 seat")
      expect(c.count_state).to eq([:demand, "Demand exceeds seats"])
      expect(c.bar?).to be(false)
    end

    it "says nothing more while demand fits the seats" do
      c = component_for(capacity: 10, item: preference_item(1))

      expect(c.count_text).to eq("1 first choice · 10 seats")
      expect(c.count_state).to be_nil
    end

    it "counts the roster of a group without a campaign and marks it over capacity" do
      c = component_for(capacity: 10, roster: 11)

      expect(c.count_text).to eq("11 / 10 members")
      expect(c.count_state).to eq([:over, "1 over capacity"])
      expect(c.bar_percent).to eq(100)
      expect(c.over_capacity?).to be(true)
    end

    it "tells the free seats" do
      c = component_for(capacity: 8, roster: 7)

      expect(c.count_state).to eq([:plain, "1 seat available"])
      expect(c.bar_percent).to eq(87)
    end

    it "shows no bar and no limit without a capacity" do
      c = component_for(capacity: nil, roster: 5)

      expect(c.count_text).to eq("5 members")
      expect(c.count_state).to eq([:plain, "No seat limit"])
      expect(c.bar?).to be(false)
    end

    it "does not divide by a capacity of zero" do
      c = component_for(capacity: 0, roster: 0)

      expect(c.bar_percent).to eq(100)
      expect(c.count_state).to eq([:full, "Full"])
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

  describe "people line" do
    it "names no tutors for a flexible group" do
      cohort = create(:cohort, context: create(:lecture))
      rendered = render_inline(described_class.new(registerable: cohort))

      expect(rendered.css(".bi-person")).to be_empty
    end

    it "names the tutors of a tutorial" do
      rendered = render_inline(described_class.new(registerable: create(:tutorial)))

      expect(rendered.css(".visually-hidden").map(&:text))
        .to include("#{I18n.t("basics.tutors")}:")
    end
  end

  describe "date line" do
    let(:lecture) { create(:seminar) }
    let(:talk) do
      create(:talk, lecture: lecture, dates: [Time.zone.local(2026, 4, 10)])
    end
    let(:item) { create(:registration_item, registerable: talk) }

    it "shows the talk date" do
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

  describe "#row_classes" do
    it "marks a group students can enroll in themselves" do
      tutorial.self_materialization_mode = "add_only"

      expect(component.row_classes).to include("group-row--self-enrollment")
    end

    it "leaves a group without self-enrollment unmarked" do
      expect(component.row_classes).to eq("group-row")
    end

    context "with an item" do
      let(:item) { double("item") }

      it "does not mark a campaign's group, whose self-enrollment is off" do
        tutorial.self_materialization_mode = "add_only"

        expect(component.row_classes).not_to include("group-row--self-enrollment")
      end
    end
  end

  describe "the self-enrollment mode" do
    let(:group) do
      create(:tutorial, lecture: create(:lecture), skip_campaigns: true,
                        self_materialization_mode: mode)
    end

    def mode_text
      render_inline(described_class.new(registerable: group))
        .css(".group-row__self-enrollment > button").first.text.squish
    end

    context "when it is off" do
      let(:mode) { :disabled }

      it "names the disabled mode on its own" do
        expect(mode_text).to eq(I18n.t("roster.self_materialization.modes.disabled"))
      end
    end

    context "when students join and leave" do
      let(:mode) { :add_and_remove }

      it "puts the label before the mode" do
        expect(mode_text).to eq(
          "#{I18n.t("roster.self_materialization.label")}: " \
          "#{I18n.t("roster.self_materialization.modes.add_and_remove")}"
        )
      end
    end
  end

  describe "the rendered row" do
    let(:lecture) { create(:lecture) }
    let(:tutorial) { create(:tutorial, lecture: lecture, title: "Mo 10", capacity: 8) }

    it "opens the roster from its title, a button the keyboard reaches" do
      row = render_inline(described_class.new(registerable: tutorial)).css("li.group-row").first
      opener = row.css("h6 button[data-roster-open]").first

      expect(opener.text.strip).to eq("Mo 10")
      expect(opener["aria-expanded"]).to eq("false")
      expect(opener["aria-controls"]).to eq("tutorial-roster-side-panel")
      expect(row["data-tutorial-roster-panel-target"]).to eq("trigger")
      expect(row["data-roster-count"]).to eq("0 / 8 members")
    end

    it "names the group on every action button" do
      rendered = render_inline(described_class.new(registerable: tutorial))
      labels = rendered.css(".group-row__actions [aria-label]").pluck("aria-label")

      expect(labels).to all(include("Mo 10"))
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
        allow(tutorial).to receive(:destruction_blockers).and_return([])
        expect(component.delete_disabled?).to be(false)
      end

      it "is true when registerable is not destructible" do
        allow(tutorial).to receive(:destruction_blockers).and_return([:roster_not_empty])
        expect(component.delete_disabled?).to be(true)
      end
    end

    context "with a campaign item" do
      let(:item) { double("item", removal_blocker_message: nil) }

      before do
        allow(tutorial).to receive(:destruction_blockers).and_return([:in_campaign])
      end

      it "is false when neither the item nor the group is blocked" do
        expect(component.delete_disabled?).to be(false)
      end

      it "is true when the item cannot leave the campaign" do
        allow(item).to receive(:removal_blocker_message).and_return("nope")
        expect(component.delete_disabled?).to be(true)
      end

      it "is true when the group itself carries data worth keeping" do
        allow(tutorial).to receive(:destruction_blockers)
          .and_return([:in_campaign, :submissions])
        expect(component.delete_disabled?).to be(true)
      end
    end
  end

  describe "the deletion confirmation" do
    let(:seminar) { create(:lecture, :is_seminar) }
    let(:talk) { create(:talk, lecture: seminar) }
    let(:component) { described_class.new(registerable: talk) }

    def rendered_confirmation
      render_inline(component).css("a[data-turbo-method='delete'][data-turbo-confirm]")
                              .first["data-turbo-confirm"]
    end

    it "asks plainly for a group that was never in a process" do
      expect(rendered_confirmation)
        .to eq(I18n.t("roster.actions.confirm_delete_group"))
    end

    # A completed campaign's registrations are deleted with the group, and the
    # teacher is the one who knows whether that history still matters.
    it "names the entries a finished process left behind" do
      campaign = create(:registration_campaign, campaignable: seminar,
                                                allocation_mode: :first_come_first_served)
      item = create(:registration_item, registration_campaign: campaign, registerable: talk)
      campaign.update!(status: :open)
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, registration_item: item)
      create(:registration_user_registration, :rejected,
             registration_campaign: campaign, registration_item: item)
      campaign.update!(status: :completed)

      expect(rendered_confirmation)
        .to eq(I18n.t("roster.actions.confirm_delete_group_with_registrations",
                      total: I18n.t("roster.actions.confirm_delete_group_total_count",
                                    count: 2),
                      confirmed: I18n.t("roster.actions.confirm_delete_group_confirmed_count",
                                        count: 1)))
    end
  end

  describe "#remove_disabled?" do
    let(:item) { double("item", removal_blocker_message: nil) }

    it "is false while the item may leave the campaign" do
      expect(component.remove_disabled?).to be(false)
    end

    it "is true once the item is pinned to the campaign" do
      allow(item).to receive(:removal_blocker_message).and_return("nope")
      expect(component.remove_disabled?).to be(true)
      expect(component.remove_disabled_title).to eq("nope")
    end
  end
end
