require "rails_helper"

RSpec.describe(SubmissionRowComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:tutor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:student2) { create(:confirmed_user) }

  let(:lecture) { create(:lecture, teacher: teacher, submission_grace_period: 70) }
  let(:tutorial) { create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id, lecture: lecture) }
  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end

  let(:submission) do
    create(:submission, assignment: assignment, tutorial: tutorial, users: [student],
                        created_at: assignment.deadline)
  end
  let(:late_rejected_submission) do
    create(:submission, assignment: assignment, tutorial: tutorial, users: [student2],
                        created_at: assignment.deadline + 2.hours, accepted: false)
  end

  let(:component_tutorial) do
    described_class.new(submission: submission, assignment: assignment, grading_scope: tutorial)
  end
  let(:component_late_rejected) do
    described_class.new(submission: late_rejected_submission, assignment: assignment,
                        grading_scope: tutorial)
  end
  let(:component_lecture) do
    described_class.new(submission: submission, assignment: assignment, grading_scope: lecture)
  end

  before do
    assignment.reload
    assessment.reload
  end

  describe "#row_id" do
    it "returns the correct row id" do
      expect(component_tutorial.row_id).to eq("submission-row-#{submission.id}")
    end
  end

  describe "#late?" do
    context "when submission is not late" do
      it "returns false" do
        allow(submission).to receive(:too_late?).and_return(false)
        expect(component_tutorial.late?).to eq(false)
      end
    end

    context "when submission is late" do
      it "returns true" do
        allow(submission).to receive(:too_late?).and_return(true)
        expect(component_tutorial.late?).to eq(true)
      end
    end
  end

  describe "#grading_enabled?" do
    context "when flipper is enabled and assignment is assessable" do
      before do
        allow(assignment).to receive(:assessable?).and_return(true)
      end

      it "returns true" do
        expect(component_tutorial.grading_enabled?).to eq(true)
      end
    end
  end

  describe "#allow_grading?" do
    context "before deadline" do
      it "returns false regardless of submission" do
        expect(component_tutorial.allow_grading?).to eq(false)
      end
    end

    context "after deadline and before grace period" do
      before { Timecop.travel(2.hours.from_now) }
      after { Timecop.return }

      it "returns false" do
        expect(component_tutorial.allow_grading?).to eq(false)
      end
    end

    context "after grace period" do
      before { Timecop.travel(3.hours.from_now) }
      after { Timecop.return }

      context "and submission is valid for marking" do
        it "returns true" do
          expect(component_tutorial.allow_grading?).to eq(true)
        end
      end

      context "and submission is not valid for marking" do
        it "returns false" do
          expect(component_late_rejected.allow_grading?).to eq(false)
        end
      end
    end
  end

  describe "#tasks" do
    it "returns persisted tasks from assignment assessment" do
      assessment
      expect(component_tutorial.tasks).to eq(assignment.assessment.persisted_tasks)
    end

    context "when assessment has no persisted tasks" do
      before { allow(assignment.assessment).to receive(:persisted_tasks).and_return(nil) }

      it "returns an empty array" do
        expect(component_tutorial.tasks).to eq([])
      end
    end
  end

  describe "#extract_task_points" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment) }
    let(:participation) do
      create(:assessment_participation, assessment: assignment.assessment, user: student)
    end

    # The row is handed the team's participations by the table; the points it
    # shows are theirs.
    context "when task points exist for the team" do
      it "returns the points" do
        Timecop.travel(assignment.deadline + 2.hours) do
          create(:assessment_task_point, task: task, points: 8,
                                         assessment_participation: participation)
        end
        component = described_class.new(submission: submission, assignment: assignment,
                                        grading_scope: tutorial,
                                        participations: [participation.reload])

        expect(component.extract_task_points(task)).to eq(8.0)
      end
    end

    context "when no task points exist for the team" do
      it "returns nil" do
        component = described_class.new(submission: submission, assignment: assignment,
                                        grading_scope: tutorial,
                                        participations: [participation])

        expect(component.extract_task_points(task)).to be_nil
      end
    end

    # A single row rendered on its own - after a save, say - is not handed
    # anything and reads the team's participations itself.
    context "when the row is not handed the participations" do
      it "reads them off the submission" do
        participation

        expect(component_tutorial.participation).to eq(participation)
      end
    end

    context "when nobody on the team has a participation" do
      it "shows no status and no points" do
        expect(component_tutorial.participation).to be_nil
        expect(component_tutorial.status).to be_nil
        expect(component_tutorial.extract_task_points(task)).to be_nil
      end
    end
  end

  describe "#task_points_input" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment, max_points: 10) }

    # The input carries a translated message, and a component can only
    # translate once it has been rendered.
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutorial)
    end

    it "renders an input with the task's id in the name" do
      html = component_tutorial.task_points_input(task, true)
      expect(html).to include("task_points[#{task.id}]")
    end

    it "sets the value to the extracted task points" do
      allow(component_tutorial).to receive(:extract_task_points).with(task).and_return(6.5)
      html = component_tutorial.task_points_input(task, true)
      expect(html).to include('value="6.5"')
    end

    it "does not cap the input at the task's max_points, allowing bonus points" do
      html = component_tutorial.task_points_input(task, true)
      expect(html).not_to include("max=")
    end

    context "when grading is not allowed" do
      it "disables the input" do
        html = component_tutorial.task_points_input(task, false)
        expect(html).to include("disabled")
      end
    end

    context "when grading is allowed" do
      it "does not disable the input" do
        html = component_tutorial.task_points_input(task, true)
        expect(html).not_to include("disabled")
      end
    end
  end

  describe "#save_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutorial)
    end

    it "names the save button for a reader" do
      button = Nokogiri::HTML.fragment(component_tutorial.save_row_button(true)).at_css("button")
      expect(button["aria-label"]).to eq(I18n.t("assessment.grading_tutorial.save_row"))
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutorial.save_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#refresh_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutorial)
    end

    it "names the reload button for a reader" do
      button = Nokogiri::HTML.fragment(component_tutorial.refresh_row_button(true)).at_css("button")
      expect(button["aria-label"]).to eq(I18n.t("assessment.grading_tutorial.reload_row"))
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutorial.refresh_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#late_submission_info" do
    let(:late_text) do
      I18n.t("assessment.task_points.late_submission",
             time: I18n.l(submission.created_at, format: :file_time))
    end

    context "when submission decision is already made (accepted is not nil)" do
      before do
        allow(vc_test_controller).to receive(:current_user).and_return(tutor)
        render_inline(component_tutorial)
        allow(submission).to receive(:accepted).and_return(true)
      end

      it "says when it was uploaded, and no more" do
        expect(component_tutorial.late_submission_info(submission, tutorial)).to eq(late_text)
      end
    end

    context "when submission decision is pending and current_user is a tutor of the tutorial" do
      before do
        allow(submission).to receive(:accepted).and_return(nil)
        allow(vc_test_controller).to receive(:current_user).and_return(tutor)
        render_inline(component_tutorial)
      end

      it "says when it was uploaded, and that the tutor decides" do
        result = component_tutorial.late_submission_info(submission, tutorial)
        expect(result).to eq("#{late_text} #{I18n.t("tutorial.late_submission_decision").strip}")
      end
    end

    context "when submission decision is pending but current_user is not a tutor" do
      before do
        allow(submission).to receive(:accepted).and_return(nil)
        allow(vc_test_controller).to receive(:current_user).and_return(student)
        render_inline(component_tutorial)
      end

      it "says when it was uploaded, and no more" do
        expect(component_tutorial.late_submission_info(submission, tutorial)).to eq(late_text)
      end
    end
  end

  # The hand-in is not late for a member who came after the deadline; the
  # row marks the member, not the team.
  describe "a member who joined after the deadline" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      submission
      Timecop.travel(assignment.deadline + 1.day)
      submission.user_submission_joins.create!(user: student2)
    end

    after { Timecop.return }

    it "is marked by name, and the hand-in stays in time" do
      html = render_inline(described_class.new(submission: submission.reload,
                                               assignment: assignment,
                                               grading_scope: tutorial))

      marker = html.css(".bi-info-circle")
      expect(marker.size).to eq(1)
      expect(marker.first["aria-label"])
        .to eq(I18n.t("assessment.task_points.joined_late",
                      time: I18n.l(Time.current, format: :file_time)))
      expect(marker.first.ancestors("div").first.text.squish).to include(student2.tutorial_name)
      expect(html.css(".bi-exclamation-triangle-fill")).to be_empty
    end

    # Whoever founded a team after the deadline handed in late, which the
    # triangle says; they did not join anything.
    it "does not mark the founder of a late team" do
      founded_late = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [create(:confirmed_user)])

      html = render_inline(described_class.new(submission: founded_late,
                                               assignment: assignment,
                                               grading_scope: tutorial))

      expect(html.css(".bi-info-circle")).to be_empty
      expect(html.css(".bi-exclamation-triangle-fill").size).to eq(1)
    end
  end

  describe "somebody a tutor put on the team" do
    let(:added) { create(:confirmed_user) }
    let!(:join) { submission.user_submission_joins.create!(user: added, added_by: tutor) }

    before { Timecop.travel(3.hours.from_now) }
    after { Timecop.return }
    let(:added_info) do
      I18n.t("assessment.task_points.added_by_tutor",
             tutor: tutor.tutorial_name, time: I18n.l(join.created_at, format: :file_time))
    end

    def render_as(user, scope: tutorial)
      allow(vc_test_controller).to receive(:current_user).and_return(user)
      render_inline(described_class.new(submission: submission.reload,
                                        assignment: assignment, grading_scope: scope))
    end

    def marks(html)
      html.css("[aria-label]").pluck("aria-label").grep(added_info)
    end

    def remove_items(html)
      toggle = html.css("button[aria-label]").find do |button|
        button["aria-label"] == I18n.t("assessment.task_points.remove_member")
      end
      return [] unless toggle

      toggle.parent.css("button.dropdown-item").map { |item| item.text.squish }
    end

    it "is named with the tutor, and offered to take off to the tutor who marks the team" do
      html = render_as(tutor)

      expect(marks(html)).to eq([added_info])
      expect(remove_items(html)).to eq([added.tutorial_name])
    end

    it "is not offered to take off while points cannot be entered" do
      assignment.update!(deadline: 1.day.from_now)

      expect(remove_items(render_as(tutor))).to be_empty
    end

    # A double name can still wrap at its hyphen.
    it "keeps its mark with the last part of the name" do
      { "Mia Zimmermann" => "Zimmermann",
        "Anna Müller-Lüdenscheidt" => "Lüdenscheidt" }.each do |name, last_part|
        added.update!(name_in_tutorials: name)
        mark = render_as(tutor).css("[aria-label]").find do |node|
          node["aria-label"] == added_info
        end

        expect(mark.parent["class"]).to include("text-nowrap")
        expect(mark.parent.text.squish).to eq(last_part)
        expect(mark.ancestors("div").first.text.squish).to eq(name)
      end
    end

    it "shares one info mark with a change of tutorial" do
      component = described_class.new(submission: submission.reload, assignment: assignment,
                                      grading_scope: tutorial)
      allow(component).to receive(:movement_info_for_user).and_call_original
      allow(component).to receive(:movement_info_for_user).with(added).and_return("Moved.")
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      html = render_inline(component)

      expect(html.css(".bi-info-circle").pluck("aria-label")).to eq(["Moved. #{added_info}"])
    end

    it "is offered to the lecturer on the lecture's table" do
      expect(remove_items(render_as(teacher, scope: lecture))).to eq([added.tutorial_name])
    end

    it "is not offered as the last one on the team, and still named with the tutor" do
      submission.user_submission_joins.find_by(user: student).destroy!
      html = render_as(tutor)

      expect(remove_items(html)).to be_empty
      expect(marks(html)).to eq([added_info])
    end

    it "is not offered to a tutor who reads the team from another tutorial" do
      html = render_as(tutor, scope: create(:tutorial, lecture: lecture))

      expect(remove_items(html)).to be_empty
      expect(marks(html)).to eq([added_info])
    end
  end

  describe "#can_enter_points?" do
    context "when grading_scope is a Tutorial" do
      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_tutorial)
        end

        it "returns true" do
          expect(component_tutorial.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_tutorial)
        end
        it "returns true" do
          expect(component_tutorial.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is a teacher" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(teacher)
          render_inline(component_tutorial)
        end
        it "returns true" do
          expect(component_tutorial.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is not an admin and not a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(student)
          render_inline(component_tutorial)
        end

        it "returns false" do
          expect(component_tutorial.can_enter_points?).to eq(false)
        end
      end
    end

    context "when grading_scope is a Lecture" do
      context "when current_user is a teacher" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(teacher)
          render_inline(component_lecture)
        end

        it "returns true" do
          expect(component_lecture.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_lecture)
        end

        it "returns false" do
          expect(component_lecture.can_enter_points?).to eq(false)
        end
      end

      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_lecture)
        end

        it "returns true" do
          expect(component_lecture.can_enter_points?).to eq(true)
        end
      end
    end
  end

  describe "the menu for putting somebody on the team" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      Timecop.travel(3.hours.from_now)
    end

    after { Timecop.return }

    def render_with(count)
      render_inline(described_class.new(submission: submission, assignment: assignment,
                                        grading_scope: tutorial,
                                        addable_members: create_list(:confirmed_user, count)))
    end

    it "offers no search over five names" do
      html = render_with(5)

      expect(html.css("button.dropdown-item").size).to eq(5)
      expect(html.css("input[type=search]")).to be_empty
    end

    it "is not offered while points cannot be entered" do
      assignment.update!(deadline: 1.day.from_now)

      expect(render_with(1).css("[data-controller=add-member-menu]")).to be_empty
    end

    it "offers a search over six names" do
      search = render_with(6).css("input[type=search]")

      expect(search.size).to eq(1)
      expect(search.first["aria-label"])
        .to eq(I18n.t("assessment.task_points.add_member_search"))
    end

    # A row drawn on its own, after a save, reads the names itself.
    it "offers nobody marked on a row of their own when it reads the names itself" do
      marked, free = create_list(:confirmed_user, 2)
      [marked, free].each { |user| create(:tutorial_membership, tutorial: tutorial, user: user) }
      Timecop.travel(3.hours.from_now) do
        row = create(:assessment_participation, :submitted, assessment: assessment,
                                                            user: marked, tutorial: tutorial)
        create(:assessment_task_point, task: create(:assessment_task, assessment: assessment),
                                       assessment_participation: row, points: 2)
        html = render_inline(described_class.new(submission: submission, assignment: assignment,
                                                 grading_scope: tutorial))

        expect(html.css("[data-controller=add-member-menu] button.dropdown-item")
                   .map { |item| item.text.squish }).to eq([free.tutorial_name])
      end
    end

    it "offers nobody who moved to another group when it reads the names itself" do
      stayed, moved = create_list(:confirmed_user, 2)
      create(:tutorial_membership, tutorial: tutorial, user: stayed)
      create(:tutorial_membership, tutorial: create(:tutorial, lecture: lecture), user: moved)
      create(:assessment_participation, assessment: assessment, user: moved, tutorial: tutorial)
      html = render_inline(described_class.new(submission: submission, assignment: assignment,
                                               grading_scope: tutorial))

      expect(html.css("[data-controller=add-member-menu] button.dropdown-item")
                 .map { |item| item.text.squish }).to eq([stayed.tutorial_name])
    end

    it "offers the menu on a rejected hand-in that a moved deadline made in time" do
      submission.update!(accepted: false,
                         last_modification_by_users_at: assignment.deadline - 1.hour)

      expect(render_with(1).css("[data-controller=add-member-menu]").size).to eq(1)
    end

    # The server would refuse anybody more; the menu says why instead.
    it "says the team is full instead of offering names" do
      submission
      assignment.lecture.update!(submission_max_team_size: 1)
      html = render_with(2)

      expect(html.at_css("[data-controller=add-member-menu]").text)
        .to include(I18n.t("assessment.task_points.team_full", max: 1))
      expect(html.css("[data-controller=add-member-menu] button.dropdown-item")).to be_empty
      expect(html.css("input[type=search]")).to be_empty
    end

    it "offers no menu without names where teams stay within one tutorial" do
      expect(render_with(0).css("[data-controller=add-member-menu]")).to be_empty
    end

    # The other tutorials are reached only by typing a name.
    context "where teams may span tutorials" do
      before { lecture.update!(cross_tutorial_teams: true) }

      it "offers the search even without names of the group's own" do
        html = render_with(0)
        menu = html.at_css("[data-controller=add-member-menu]")

        expect(menu["data-add-member-menu-url-value"])
          .to eq(Rails.application.routes.url_helpers
                      .add_member_candidates_submission_path(submission,
                                                             grading_scope_type: "tutorial"))
        expect(html.css("input[type=search]").size).to eq(1)
        expect(html.text).to include(I18n.t("assessment.task_points.add_member_search_elsewhere",
                                            min: Submission::MEMBER_SEARCH_MIN_LENGTH))
        expect(html.css("#add-member-elsewhere-#{submission.id}").size).to eq(1)
      end

      it "offers no search on a rejected hand-in" do
        html = render_inline(described_class.new(submission: late_rejected_submission,
                                                 assignment: assignment, grading_scope: tutorial,
                                                 addable_members: []))

        expect(html.css("[data-controller=add-member-menu]")).to be_empty
      end
    end
  end

  describe "rendering" do
    before do
      submission
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutorial)
    end

    it "renders the submission row" do
      render_inline(component_tutorial)
      expect(rendered_content).to include("submission-row-#{submission.id}")
    end
  end

  describe "a team across tutorials" do
    let(:other_tutor) { create(:confirmed_user) }
    let(:other_tutorial) do
      create(:tutorial, :with_tutor_by_id, tutor_id: other_tutor.id, lecture: lecture,
                                           title: "Tuesday")
    end
    let(:team) do
      create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                            users: [student, student2])
    end

    before do
      lecture.update!(cross_tutorial_teams: true)
      create(:tutorial_membership, tutorial: tutorial, user: student)
      create(:tutorial_membership, tutorial: other_tutorial, user: student2)
    end

    def render_for(user, scope)
      allow(vc_test_controller).to receive(:current_user).and_return(user)
      render_inline(described_class.new(submission: team, assignment: assignment,
                                        grading_scope: scope))
    end

    def labelled(html, label)
      html.css("[aria-label]").select { |node| node["aria-label"] == label }
    end

    let(:hand_over) { I18n.t("assessment.task_points.hand_over") }

    it "offers the marking tutor to hand it over to the other member's tutorial" do
      html = render_for(tutor, tutorial)

      expect(labelled(html, hand_over)).to be_present
      expect(html.css("button.dropdown-item").map { |item| item.text.strip })
        .to include(other_tutorial.title_with_tutors)
    end

    it "shows the other tutor the team read-only, saying who marks it" do
      create(:assessment_task, assessment: assessment, max_points: 10)
      html = render_for(other_tutor, other_tutorial)

      expect(html.text).to include(I18n.t("assessment.task_points.marked_elsewhere",
                                          tutorial: tutorial.title_with_tutors))
      inputs = html.css("input[type=number]")
      expect(inputs).to be_present
      expect(inputs.pluck("disabled")).to all(be_present)
      expect(labelled(html, I18n.t("assessment.grading_tutorial.save_row"))).to be_empty
      expect(labelled(html, hand_over)).to be_empty
      expect(labelled(html, I18n.t("assessment.grading_tutorial.show_hand_in"))).to be_present
    end

    it "lets the other tutor copy only their own student's address" do
      html = render_for(other_tutor, other_tutorial)

      expect(html.css("[data-clipboard-text-value]").first["data-clipboard-text-value"])
        .to eq(student2.email)
    end

    it "offers the hand-over from the table's tutorials without asking the submission" do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      allow(team).to receive(:hand_over_targets).and_raise("asked")

      html = render_inline(described_class.new(
                             submission: team, assignment: assignment, grading_scope: tutorial,
                             participations: [],
                             member_tutorials: { student.id => tutorial,
                                                 student2.id => other_tutorial }
                           ))

      expect(html.css("button.dropdown-item").map { |item| item.text.strip })
        .to eq([other_tutorial.title_with_tutors])
    end

    it "offers no hand-over once the team has a correction" do
      team.update!(correction: File.open("#{SPEC_FILES}/manuscript.pdf", "rb"))

      expect(labelled(render_for(tutor, tutorial), hand_over)).to be_empty
    end
  end
end
