require "rails_helper"

RSpec.describe(ParticipationComponent, type: :component) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:course) { create(:course, title: "Linear Algebra") }
  let(:lecture) { create(:lecture, course: course) }
  let(:user) { create(:confirmed_user, email: "student@play") }

  describe "policy rejection messages" do
    it "renders finalization-specific email-policy rejections" do
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Email checked tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :institutional_email,
        :for_finalization,
        registration_campaign: campaign,
        config: { "allowed_domains" => ["example.com"] }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "institutional_email_mismatch"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Email checked tutorial registration")
      expect(rendered.text).to include("Rejected")
      expect(rendered.text).to include(
        "At the time this registration process was finalized"
      )
      expect(rendered.text).to include("required email domains example.com")
      expect(rendered.text).not_to include("Your current email domain is play")
      expect(rendered.css("a")).to be_empty
    end

    it "uses the stored rejection code after the student fixes the policy issue" do
      prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Priority registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "prerequisite_not_met",
        rejection_reason_label: "Prerequisite was missing."
      )
      create(
        :registration_user_registration,
        :confirmed,
        registration_campaign: prerequisite_campaign,
        registration_item: prerequisite_campaign.registration_items.first,
        user: user
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(
        "At the time this registration process was finalized, you did not have a " \
        "confirmed registration in"
      )
      expect(rendered.text).to include("Priority registration")
      expect(rendered.text).not_to include("Your registration was rejected.")
    end

    it "renders the prerequisite campaign label for prerequisite-policy rejections" do
      prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Priority registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: policy,
        rejection_reason_code: "prerequisite_not_met"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(
        "At the time this registration process was finalized, you did not have a " \
        "confirmed registration in"
      )
      expect(rendered.text).to include("Priority registration")
    end

    it "uses the stored policy id when multiple policies share a rejection code" do
      wrong_prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Wrong prerequisite registration",
        items_count: 1
      )
      correct_prerequisite_campaign = create(
        :registration_campaign,
        :completed,
        campaignable: lecture,
        description: "Correct prerequisite registration",
        items_count: 1
      )
      campaign = create(
        :registration_campaign,
        :first_come_first_served,
        :with_items,
        campaignable: lecture,
        description: "Follow-up tutorial registration",
        items_count: 1
      )
      create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => wrong_prerequisite_campaign.id }
      )
      correct_policy = create(
        :registration_policy,
        :prerequisite_campaign,
        :for_finalization,
        registration_campaign: campaign,
        config: { "prerequisite_campaign_id" => correct_prerequisite_campaign.id }
      )
      campaign.update!(status: :completed)
      create(
        :registration_user_registration,
        :policy_rejected,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first,
        user: user,
        rejection_policy: correct_policy,
        rejection_reason_code: "prerequisite_not_met"
      )

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Correct prerequisite registration")
      expect(rendered.text).not_to include("Wrong prerequisite registration")
    end
  end

  describe "standings before the allocation" do
    it "leaves the preferences of a campaign still open to its own row" do
      campaign = create(:registration_campaign, :preference_based, :open,
                        campaignable: lecture, items_count: 1)
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first,
             user: user, preference_rank: 1)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to be_blank
    end

    it "shows saved preferences as waiting for the allocation" do
      campaign = create(:registration_campaign, :preference_based, :closed,
                        campaignable: lecture, items_count: 2)
      first, second = campaign.registration_items.order(:id).to_a
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: second, user: user,
                                              preference_rank: 1)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: first, user: user,
                                              preference_rank: 2)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
      expect(rendered.text.squish)
        .to include("1st #{second.title} · 2nd #{first.title}")
    end

    it "keeps every ranked choice while the allocation awaits finalization" do
      campaign = create(:registration_campaign, :preference_based, :processing,
                        campaignable: lecture, items_count: 2)
      first, second = campaign.registration_items.order(:id).to_a
      create(:registration_user_registration, :confirmed, registration_campaign: campaign,
                                                          registration_item: first,
                                                          user: user, preference_rank: 1)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: second, user: user,
                                              preference_rank: 2)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
      expect(rendered.text.squish).to include("1st #{first.title} · 2nd #{second.title}")
    end

    it "keeps the allocation pending for a place assigned outside the choices" do
      campaign = create(:registration_campaign, :preference_based, :processing,
                        campaignable: lecture, items_count: 1)
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first,
             user: user, preference_rank: nil)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Waiting for allocation")
    end

    it "says that a first come, first served place is checked again" do
      campaign = create(:registration_campaign, :first_come_first_served, :closed,
                        campaignable: lecture, items_count: 1)
      item = campaign.registration_items.first
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, registration_item: item, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include(item.registerable.title)
      expect(rendered.text).to include("Registered")
      expect(rendered.text)
        .to include("The requirements are checked again when the process is finalized.")
    end
  end

  describe "outcomes" do
    it "shows a capacity rejection with the preferences that could not be met" do
      campaign = create(:registration_campaign, :preference_based, :with_items,
                        campaignable: lecture, items_count: 1,
                        description: "Tutorial allocation")
      campaign.update!(status: :completed)
      item = campaign.registration_items.first
      create(:registration_user_registration, :capacity_rejected,
             registration_campaign: campaign, registration_item: item,
             user: user, preference_rank: 1)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tutorial allocation")
      expect(rendered.text).to include("No place")
      expect(rendered.text).to include("Your preferences: 1st #{item.title}")
    end

    it "shows the tutorial a student was assigned to" do
      tutorial = create(:tutorial, lecture: lecture, title: "Tutorial 4")
      create(:tutorial_membership, tutorial: tutorial, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tutorial 4")
      expect(rendered.text).to include("Assigned")
    end

    it "gives a member of a tutorial the address of each tutor" do
      tutor = create(:confirmed_user, name: "Tara Tutor", email: "tara@play")
      tutorial = create(:tutorial, lecture: lecture, title: "Tutorial 4", tutors: [tutor])
      create(:tutorial_membership, tutorial: tutorial, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tara Tutor (tara@play)")
      expect(rendered.css("a[href='mailto:tara@play']").map(&:text)).to eq(["tara@play"])
    end

    it "names the tutors to a student only registered, without their address" do
      campaign = create(:registration_campaign, :first_come_first_served, :closed,
                        campaignable: lecture, items_count: 1)
      item = campaign.registration_items.first
      tutor = create(:confirmed_user, name: "Tara Tutor", email: "tara@play")
      item.registerable.update!(tutors: [tutor])
      create(:registration_user_registration, :confirmed,
             registration_campaign: campaign, registration_item: item, user: user)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Tara Tutor")
      expect(rendered.text).not_to include("tara@play")
    end

    it "says when a student was taken off an exam list" do
      exam = create(:exam, lecture: lecture)
      create(:exam_roster_entry, exam: exam, user: user, excluded_at: Time.current)

      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to include("Removed from the exam list")
    end

    it "renders nothing without any standing" do
      rendered = render_inline(described_class.new(lecture: lecture, user: user))

      expect(rendered.text).to be_blank
    end
  end

  describe "published results" do
    let(:exam) { create(:exam, lecture: lecture, title: "Final Exam") }
    let(:assessment) { exam.assessment }
    let!(:first_task) do
      create(:assessment_task, assessment: assessment, max_points: 10, position: 1,
                               description: nil)
    end
    let!(:second_task) do
      create(:assessment_task, assessment: assessment, max_points: 20, position: 2,
                               description: "Proof")
    end
    let(:participation) do
      create(:assessment_participation, assessment: assessment, user: user)
    end

    before do
      create(:exam_roster_entry, exam: exam, user: user)
      create(:assessment_task_point, assessment_participation: participation,
                                     task: first_task, points: 7.5)
      create(:assessment_task_point, assessment_participation: participation,
                                     task: second_task, points: 12)
      participation.update!(status: :reviewed, points_total: 19.5, grade_numeric: 2.3)
    end

    def render_row
      render_inline(described_class.new(lecture: lecture, user: user))
        .css("[data-testid=participation-row]").find { |row| row.text.include?("Final Exam") }
    end

    it "shows nothing of the result before it is published" do
      row = render_row

      expect(row.text).to include("On the exam list")
      expect(row.text).not_to include("2.3")
      expect(row.css("details")).to be_empty
    end

    it "shows the grade, the points and the points per problem once published" do
      assessment.update!(results_published_at: Time.current)

      row = render_row

      expect(row.text.squish).to include("Grade 2.3")
      expect(row.text.squish).to include("19.5 of 30 points")
      problems = row.css("details dt").map { |term| term.text.squish }
      expect(problems).to eq(["Problem 1", "Proof"])
      expect(row.css("details dd").map { |value| value.text.squish }).to eq(["7.5 / 10", "12 / 20"])
    end

    # A grade entered without any points is no score of zero.
    it "shows a grade given without points, but no points" do
      participation.task_points.destroy_all
      participation.update!(points_total: nil)
      assessment.update!(results_published_at: Time.current)

      row = render_row

      expect(row.text.squish).to include("Grade 2.3")
      expect(row.text).not_to include("points")
      expect(row.css("details")).to be_empty
    end

    it "says so for a student who did not take part" do
      participation.update!(status: :absent, grade_numeric: 5.0)
      assessment.update!(results_published_at: Time.current)

      row = render_row

      expect(row.text.squish).to include("Did not take part")
      expect(row.text.squish).to include("Grade 5.0")
      expect(row.css("details")).to be_empty
    end

    it "says so for a student who was exempted" do
      participation.update!(status: :exempt, grade_numeric: nil)
      assessment.update!(results_published_at: Time.current)

      expect(render_row.text.squish).to include("Exempt")
    end

    it "shows a speaker the talk's grade but never the lecturer's note" do
      seminar = create(:lecture, sort: "seminar")
      talk = create(:talk, lecture: seminar, title: "Sylow theorems")
      create(:speaker_talk_join, talk: talk, speaker: user)
      create(:assessment_participation, assessment: talk.assessment, user: user,
                                        status: :reviewed, grade_numeric: 1.7,
                                        note: "Rushed the last proof")
      talk.assessment.update!(results_published_at: Time.current)

      rendered = render_inline(described_class.new(lecture: seminar, user: user))

      expect(rendered.text.squish).to include("Grade 1.7")
      expect(rendered.text).not_to include("Rushed the last proof")
    end
  end

  # A student clicked "Leave" by mistake in a group they could not join again
  # themselves; the button now asks first and says what follows.
  describe "leaving a group" do
    let(:tutorial) do
      create(:tutorial, lecture: lecture, title: "Mo 10", skip_campaigns: true,
                        self_materialization_mode: :add_and_remove)
    end

    def participation(key, **)
      I18n.t("registration.user_registration.participation.#{key}", **)
    end

    def render_participation
      render_inline(described_class.new(lecture: lecture, user: user))
    end

    def row(rendered)
      rendered.css("[data-testid='participation-row']").find { |r| r.text.include?("Mo 10") }
    end

    def dialog_text(rendered)
      rendered.at_css("#leave-tutorial-#{tutorial.id} .modal-body").text.squish
    end

    before { lecture.add_user_to_roster!(user) }

    context "when another group with enrollment remains" do
      def dialog_text_for(mode, capacity: nil)
        tutorial.update!(self_materialization_mode: mode, capacity: capacity)
        tutorial.add_user_to_roster!(user)
        dialog_text(render_participation)
      end

      before do
        create(:cohort, :enrollment, context: lecture, skip_campaigns: true)
          .add_user_to_roster!(user)
      end

      it "opens the group's own dialog from the row's button" do
        tutorial.add_user_to_roster!(user)

        button = row(render_participation).at_css("button")

        expect(button.text.squish).to eq(participation(:leave_tutorial))
        expect(button["data-bs-target"]).to eq("#leave-tutorial-#{tutorial.id}")
      end

      it "says the course stays, but without a tutorial no sheet can be handed in" do
        expect(dialog_text_for(:add_and_remove)).to include(participation(:leave_stays_tutorial))
      end

      it "warns that a group which only lets students leave takes nobody back" do
        expect(dialog_text_for(:remove_only)).to include(participation(:rejoin_final))
      end

      it "says nothing about the way back where joining again is possible" do
        expect(dialog_text_for(:add_and_remove, capacity: 20))
          .not_to include(participation(:rejoin_final))
      end
    end

    context "when the group is the student's last one and nothing else remains" do
      before { tutorial.add_user_to_roster!(user) }

      it "opens the dialog for leaving the course, which says why" do
        rendered = render_participation

        expect(row(rendered).at_css("button")["data-bs-target"])
          .to eq("##{LeaveLectureComponent::ID}")
        expect(rendered.at_css("#leave-tutorial-#{tutorial.id}")).to be_nil
        expect(rendered.at_css("##{LeaveLectureComponent::ID}").text.squish)
          .to include(I18n.t("lecture_home.leave.only_group", group: "Mo 10"))
      end

      it "points to switching, and offers it in the dialog for leaving the course" do
        lecture.update!(released: "all")
        tuesday = create(:tutorial, lecture: lecture, title: "Di 12", skip_campaigns: true,
                                    self_materialization_mode: :add_and_remove)

        rendered = render_participation

        expect(row(rendered).text.squish).to include(participation(:switch_hint))
        switch = rendered.at_css("##{LeaveLectureComponent::ID} .dropdown-menu form")
        expect(switch["action"])
          .to eq(Rails.application.routes.url_helpers.self_switch_tutorial_path(tuesday))
        expect(switch.text.squish).to eq("Di 12")
      end
    end

    # A repeater may give up the tutorial and keep the registration that
    # leaving the course would withdraw.
    context "when the group is the student's last one and a registration remains" do
      let(:campaign) { create(:registration_campaign, :open, campaignable: lecture) }

      before do
        tutorial.add_user_to_roster!(user)
        create(:registration_user_registration, :confirmed, user: user,
                                                            registration_campaign: campaign)
      end

      it "opens its own dialog, saying that taking part ends and the registration stays" do
        create(:assignment, lecture: lecture)

        rendered = render_participation

        expect(row(rendered).at_css("button")["data-bs-target"])
          .to eq("#leave-tutorial-#{tutorial.id}")
        expect(dialog_text(rendered)).to include(
          participation(:leave_no_sheets),
          participation(:leave_keeps_registration_dashboard,
                        title: campaign.student_facing_title),
          participation(:leave_points_stay)
        )
        expect(rendered.at_css("##{LeaveLectureComponent::ID}").text.squish)
          .not_to include(I18n.t("lecture_home.leave.only_group", group: "Mo 10"))
      end

      it "opens the dialog for leaving the course while a result holds the student" do
        allow_any_instance_of(Rosters::LectureLeave)
          .to receive(:last_place_blockers).and_return([:held])

        expect(row(render_participation).at_css("button")["data-bs-target"])
          .to eq("##{LeaveLectureComponent::ID}")
      end
    end
  end
end
