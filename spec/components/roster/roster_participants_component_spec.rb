require "rails_helper"

RSpec.describe(RosterParticipantsComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:group_type) { :all }
  let(:participants) { lecture.lecture_memberships }
  let(:pagy) { nil }
  let(:component) do
    lecture.reload
    described_class.new(lecture: lecture, group_type: group_type,
                        participants: participants, pagy: pagy)
  end

  describe "#participants" do
    let!(:users) { create_list(:user, 3) }

    before do
      users.each { |u| create(:lecture_membership, lecture: lecture, user: u) }
    end

    it "returns the lecture memberships" do
      expect(component.participants.size).to eq(3)
    end
  end

  describe "pagination" do
    context "when pagy is provided" do
      let(:pagy) do
        double("Pagy",
               series: [1, "2", 3],
               page: 1,
               pages: 3,
               next: 2,
               prev: nil,
               vars: { page: 1, count: 100, limit: 10 })
      end

      it "enables pagination" do
        expect(component.pagy).to eq(pagy)
      end
    end
  end

  describe "#pagination_nav" do
    let(:pagy) do
      # Use a double because Pagy.new behavior is inconsistent in this environment
      double("Pagy",
             series: [1, "2", 3],
             page: 1,
             pages: 3,
             next: 2,
             prev: nil,
             vars: { page: 1, count: 100, limit: 10 },
             series_nav: "expected_html")
    end
    let(:group_type) { :tutorials }
    let(:component) do
      described_class.new(lecture: lecture, group_type: group_type, participants: participants,
                          pagy: pagy)
    end

    before do
      # Helper needs to be available for path generation
      allow_any_instance_of(RosterParticipantsComponent)
        .to receive(:helpers).and_wrap_original do |original_method, *args|
        original_method.call(*args)
      end
    end

    context "when there is only one page" do
      let(:pagy) { double("Pagy", pages: 1) }

      it "returns nil" do
        # Ensure we don't try to render pagy
        render_inline(component)
        expect(component.pagination_nav).to be_nil
        expect(rendered_content).not_to include("pagy-series-nav")
      end
    end

    context "when pagy is nil" do
      let(:pagy) { nil }

      it "returns nil" do
        render_inline(component)
        expect(component.pagination_nav).to be_nil
        expect(rendered_content).not_to include("pagy-series-nav")
      end
    end
  end
  describe "#pagination_nav" do
    it "returns nil if no pagy" do
      expect(described_class.new(lecture: lecture, group_type: "tutorial",
                                 pagy: nil).pagination_nav).to be_nil
    end

    it "returns nil if pagy has 1 or fewer pages" do
      pagy = double("Pagy", pages: 1)
      expect(described_class.new(lecture: lecture, group_type: "tutorial",
                                 pagy: pagy).pagination_nav).to be_nil
    end

    it "calls helpers.pagy_series_nav and constructs querify correctly" do
      pagy = double("Pagy", pages: 2)
      c = described_class.new(lecture: lecture, group_type: ["t1", "t2"],
                              search_string: "foo", pagy: pagy)

      helpers_mock = double("helpers")
      allow(c).to receive(:helpers).and_return(helpers_mock)
      allow(helpers_mock).to receive(:lecture_roster_participants_path)
        .with(lecture).and_return("/path")

      expect(helpers_mock).to receive(:pagy_series_nav)
        .with(pagy, path: "/path",
                    anchor_string: 'data-turbo-stream="true"',
                    querify: kind_of(Proc)) do |_, options|
        querify = options[:querify]

        # Test the lambda querify inside
        mock_params = {}
        querify.call(mock_params)

        expect(mock_params).not_to have_key("filter")
        expect(mock_params["search"]).to eq("foo")
        expect(mock_params["group_type"]).to eq(["t1", "t2"])

        "HTML"
      end

      expect(c.pagination_nav).to eq("HTML")
    end

    it "constructs string group_type for querify" do
      pagy = double("Pagy", pages: 2)
      c = described_class.new(lecture: lecture, group_type: :tutorial, pagy: pagy)

      helpers_mock = double("helpers")
      allow(c).to receive(:helpers).and_return(helpers_mock)
      allow(helpers_mock).to receive(:lecture_roster_participants_path)
        .with(lecture).and_return("/path")

      expect(helpers_mock).to receive(:pagy_series_nav)
        .with(pagy, path: "/path",
                    anchor_string: 'data-turbo-stream="true"',
                    querify: kind_of(Proc)) do |_, options|
        querify = options[:querify]
        mock_params = {}
        querify.call(mock_params)

        expect(mock_params["group_type"]).to eq("tutorial")
        "HTML"
      end

      c.pagination_nav
    end
  end

  describe "#user_memberships edge cases" do
    it "handles talks successfully" do
      user = create(:confirmed_user)
      seminar = create(:lecture, term: create(:term), sort: "seminar")
      talk = create(:talk, lecture: seminar)
      create(:speaker_talk_join, speaker: user, talk: talk)

      c = described_class.new(lecture: seminar, group_type: "talk",
                              participants: [double(user_id: user.id)])

      # force internal calculation and lookup talk mapping
      expect(c.send(:user_memberships)[user.id]).to include("Talk-#{talk.id}")
    end

    it "handles cohorts successfully" do
      user = create(:confirmed_user)
      cohort = create(:cohort, context: lecture)
      create(:cohort_membership, user: user, cohort: cohort)

      c = described_class.new(lecture: lecture, group_type: "tutorial",
                              participants: [double(user_id: user.id)])

      expect(c.send(:user_memberships)[user.id]).to include("Cohort-#{cohort.id}")
    end
  end

  describe "#participant_groups" do
    it "returns the groups the user is part of" do
      user = create(:confirmed_user)
      tutorial = create(:tutorial, lecture: lecture)
      cohort = create(:cohort, context: lecture)

      create(:tutorial_membership, user: user, tutorial: tutorial)
      create(:cohort_membership, user: user, cohort: cohort)

      c = described_class.new(lecture: lecture, group_type: "tutorial",
                              participants: [double(user_id: user.id, user: user)])

      groups = c.participant_groups(user)

      expect(groups).to match_array([tutorial, cohort])
    end

    it "includes the exam lists the user is on" do
      user = create(:confirmed_user)
      exam = create(:exam, :without_campaign, lecture: lecture, title: "Final")
      exam.add_user_to_roster!(user)

      c = described_class.new(lecture: lecture, group_type: "tutorial",
                              participants: [double(user_id: user.id, user: user)])

      expect(c.participant_groups(user)).to eq([exam])
    end
  end

  describe "the study program column" do
    let(:math) { create(:subject, name: "Mathematik") }
    let(:program) { create(:program, subject: math, name: "M.Sc.", degree: :msc) }
    let(:pagy) { double("Pagy", pages: 1, page: 1) }

    before do
      create(:lecture_membership, lecture: lecture, user: create(:user, program: program))
    end

    it "shows each participant's program to the teacher" do
      render_inline(component)

      expect(rendered_content).to include("Mathematik: M.Sc.")
    end

    it "offers the address to copy instead of a column of its own" do
      render_inline(component)

      document = Nokogiri::HTML.fragment(rendered_content)
      expect(document.css("th").map { |th| th.text.strip }).not_to include(I18n.t("basics.email"))
      expect(document.at_css("button[aria-label^='#{I18n.t("buttons.copy_email_address")}: ']"))
        .to be_present
    end
  end

  describe "search field rendering" do
    it "keeps the search form in the header cluster and streams updates" do
      render_inline(component)

      expect(rendered_content).to include('id="roster_participants_top_nav"')
      expect(rendered_content).to include('id="roster_participants_header_controls"')
      expect(rendered_content).to include('id="roster_participants_results"')
      expect(rendered_content).to include('data-turbo-stream="true"')
      expect(rendered_content).to include('id="roster-participants-search-field"')
      expect(rendered_content).to include("btn-close")
    end
  end

  describe ".section_targets" do
    it "defines turbo stream target IDs for streamable sections" do
      expect(described_class.section_targets).to eq(
        view_switch: "roster_participants_view_switch",
        campaign_switch: "roster_participants_campaign_switch",
        top_nav: "roster_participants_top_nav",
        header_controls: "roster_participants_header_controls",
        results: "roster_participants_results"
      )
    end
  end

  describe "people only in groups without enrollment" do
    let(:outsider) { create(:confirmed_user) }
    let(:participants) { LectureMembership.none }

    before do
      waitlist = create(:cohort, context: lecture, propagate_to_lecture: false)
      waitlist.add_user_to_roster!(outsider)
      enrolled = create(:confirmed_user)
      create(:lecture_membership, lecture: lecture, user: enrolled)
      waitlist.add_user_to_roster!(enrolled)
    end

    it "counts those not enrolled and says why they are missing" do
      rendered = render_inline(component)

      expect(rendered.text).to include(I18n.t("roster.outside_enrollment", count: 1))
    end
  end

  describe "what remains for someone who has left" do
    let(:former) { create(:confirmed_user, name_in_tutorials: "Lina Berg") }
    let(:component) do
      described_class.new(lecture: lecture, group_type: group_type,
                          participants: lecture.excluded_lecture_memberships, view: "left")
    end
    let(:remaining_cell) do
      row = render_inline(component).css("tr").find { |tr| tr.text.include?("Lina Berg") }
      row.css("td")[3]
    end
    let(:routes) { Rails.application.routes.url_helpers }

    before { create(:lecture_membership, lecture: lecture, user: former).exclude!(by: former) }

    it "links the flexible groups without enrollment and the running registrations" do
      waitlist = create(:cohort, context: lecture, title: "Warteliste Di")
      waitlist.add_user_to_roster!(former)
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :pending, user: former,
                                                        registration_campaign: campaign)

      badges = remaining_cell.css("a.badge").map { |link| [link.text.strip, link["href"]] }

      expect(badges).to eq(
        [["Warteliste Di",
          routes.edit_lecture_path(lecture, tab: "groups", open_roster: "Cohort-#{waitlist.id}")],
         [I18n.t("roster.left.registered_for", title: campaign.student_facing_title),
          routes.edit_lecture_path(lecture, tab: "participants", view: "registered",
                                            campaign: campaign.id)]]
      )
    end

    # The registered view leaves exam campaigns out.
    it "links an exam registration to the exams tab" do
      exam_campaign = create(:exam, lecture: lecture).registration_campaign
      exam_campaign.update_columns(status: Registration::Campaign.statuses[:open], # rubocop:disable Rails/SkipsModelValidations
                                   registration_deadline: 1.week.from_now)
      create(:registration_user_registration, :pending,
             user: former, registration_campaign: exam_campaign,
             registration_item: exam_campaign.registration_items.first)

      expect(remaining_cell.at_css("a.badge")["href"])
        .to eq(routes.edit_lecture_path(lecture, tab: "exams"))
    end

    it "shows a dash when nothing remains" do
      expect(remaining_cell.text.strip).to eq("–")
    end
  end

  describe "readmitting someone who has left" do
    let(:former) { create(:confirmed_user, name_in_tutorials: "Lina Berg") }
    let(:participants) { lecture.excluded_lecture_memberships }
    let(:component) do
      lecture.reload
      described_class.new(lecture: lecture, group_type: group_type,
                          participants: participants, view: "left")
    end
    let(:group_select) do
      label = I18n.t("roster.left.group_for", user: "Lina Berg")
      render_inline(component).at_css("select[aria-label='#{label}']")
    end

    before { create(:lecture_membership, lecture: lecture, user: former).exclude!(by: former) }

    it "offers the groups with enrollment that the staff can add people to" do
      create(:tutorial, lecture: lecture, title: "Mo 10", skip_campaigns: true)
      create(:tutorial, lecture: lecture, title: "Di 12", skip_campaigns: false)
      create(:cohort, context: lecture, title: "Repeaters", propagate_to_lecture: true,
                      skip_campaigns: true)
      create(:cohort, context: lecture, title: "Waitlist", propagate_to_lecture: false)

      expect(group_select.css("option").map(&:text))
        .to eq([I18n.t("roster.left.choose_group"), "Mo 10", "Repeaters"])
      expect(group_select["required"]).to be_present
    end

    it "says why nobody can be readmitted while a registration process manages every group" do
      create(:tutorial, lecture: lecture, skip_campaigns: false)

      rendered = render_inline(component)

      expect(rendered.text).to include(I18n.t("roster.left.no_open_group"))
      expect(rendered.css("select")).to be_empty
    end

    it "offers no readmission in a lecture without groups with enrollment" do
      create(:cohort, context: lecture, propagate_to_lecture: false)

      rendered = render_inline(component)

      expect(rendered.text).to include(I18n.t("roster.left.no_open_group"))
      expect(rendered.css("form[action$='/roster/members']")).to be_empty
    end
  end

  # Counts the people the tab lists: a group without enrollment or a running
  # registration does not put anybody on it.
  describe "study programs" do
    let(:participants) { LectureMembership.none }
    let(:math) { create(:subject, name: "Mathematics") }
    let(:bachelor) { create(:program, subject: math, name: "B.Sc. 100%", degree: :bsc100) }

    before do
      enrolled = create(:confirmed_user, program: bachelor)
      create(:lecture_membership, lecture: lecture, user: enrolled)
      waitlist = create(:cohort, context: lecture, propagate_to_lecture: false)
      waitlist.add_user_to_roster!(create(:confirmed_user, program: bachelor))
    end

    it "counts the enrolled only" do
      table = render_inline(component).css("details tbody tr, details tfoot tr")
      rows = table.map { |row| row.css("th, td").map { |cell| cell.text.squish } }

      expect(rows).to eq([["Mathematics: B.Sc. 100%", "1"],
                          [I18n.t("roster.programs.total"), "1"]])
    end
  end
end
