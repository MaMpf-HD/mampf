require "rails_helper"

RSpec.describe(TutorialMarkingTableComponent, type: :component) do
  let(:lecture) { create(:lecture, submission_grace_period: 70) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end

  before do
    assignment.reload
    assessment&.reload
  end

  describe "when grading_scope is a Tutorial" do
    let(:component) do
      described_class.new(assignment: assignment, grading_scope: tutorial)
    end

    describe "#grading_enabled?" do
      context "when assignment is assessable" do
        it "returns true" do
          expect(component.grading_enabled?).to eq(true)
        end
      end
    end

    describe "#tasks" do
      let!(:task) { create(:assessment_task, assessment: assessment) }

      it "returns persisted tasks from assignment assessment" do
        expect(component.tasks).to eq(assignment.reload.assessment.persisted_tasks)
      end
    end

    describe "the blank points hint" do
      let(:hint) { I18n.t("assessment.grading_tutorial.blank_points_hint") }

      before do
        allow(vc_test_controller).to receive(:current_user).and_return(lecture.teacher)
        create(:tutorial_membership, tutorial: tutorial, user: create(:confirmed_user))
      end

      it "stands above the points inputs" do
        create(:assessment_task, assessment: assessment)

        expect(render_inline(component).text).to include(hint)
      end

      it "is left out while the sheet has no tasks to enter points on" do
        expect(render_inline(component).text).not_to include(hint)
      end
    end

    # Somebody marked on a row of their own is done with the sheet; the
    # server would refuse them anyway.
    describe "the menu for putting somebody on a team" do
      let(:marked) { create(:confirmed_user, name_in_tutorials: "Leon Fischer") }
      let(:free) { create(:confirmed_user, name_in_tutorials: "Mia Bauer") }

      before do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [create(:confirmed_user)])
        [marked, free].each { |user| create(:tutorial_membership, tutorial: tutorial, user: user) }
        Timecop.travel(3.hours.from_now)
        row = create(:assessment_participation, :submitted, assessment: assessment,
                                                            user: marked, tutorial: tutorial)
        create(:assessment_task_point, task: create(:assessment_task, assessment: assessment),
                                       assessment_participation: row, points: 2)
      end

      after { Timecop.return }

      def offered(scope)
        render_inline(described_class.new(assignment: assignment.reload, grading_scope: scope))
          .css("[data-controller=add-member-menu] button.dropdown-item")
          .map { |item| item.text.squish }
      end

      it "offers nobody marked on a row of their own" do
        tutor = create(:confirmed_user)
        tutorial.tutors << tutor
        allow(vc_test_controller).to receive(:current_user).and_return(tutor)

        expect(offered(tutorial)).to eq(["Mia Bauer"])
      end

      it "offers nobody marked on a row of their own on the lecture's table" do
        allow(vc_test_controller).to receive(:current_user).and_return(lecture.teacher)

        expect(offered(lecture)).to eq(["Mia Bauer"])
      end
    end

    describe "#rows?" do
      context "when there are submissions" do
        let!(:submission) do
          create(:submission, :with_manuscript,
                 assignment: assignment, tutorial: tutorial,
                 users: [create(:confirmed_user)])
        end

        it "returns true" do
          expect(component.rows?).to be(true)
        end
      end

      context "when somebody is in the group without a hand-in" do
        before { create(:tutorial_membership, tutorial: tutorial, user: create(:confirmed_user)) }

        it "returns true" do
          expect(component.rows?).to be(true)
        end
      end

      context "when nobody is in the group and nothing was handed in" do
        it "returns false" do
          expect(component.rows?).to be(false)
        end
      end
    end

    # Everybody in the group is expected at a test; the row has its id before
    # the table is drawn, and takes points without a hand-in recorded first.
    context "when the assignment is a test" do
      let!(:assignment) do
        create(:assignment, :with_lecture, lecture: lecture, kind: :test,
                                           deadline: 1.week.from_now)
      end
      let(:member) { create(:confirmed_user, name: "Ada") }

      before do
        allow(vc_test_controller).to receive(:current_user).and_return(lecture.teacher)
        create(:tutorial_membership, tutorial: tutorial, user: member)
        create(:assessment_task, assessment: assessment, max_points: 10)
      end

      it "creates the member's row as it draws it, and offers the points" do
        expect { render_inline(component) }
          .to change { assessment.assessment_participations.where(user: member).count }
          .from(0).to(1)
        expect(assessment.assessment_participations.find_by(user: member))
          .to have_attributes(status: "pending", submitted_at: nil, points_total: nil)

        page = render_inline(component)
        row = page.css("tr[id^=points-participation-row-]").first
        expect(row["id"]).not_to include("user-")
        expect(row.css("input[type=number]")).to be_present
        expect(row.text).not_to include(I18n.t("assessment.grading_tutorial.record_first"))
        expect(assessment.assessment_participations.find_by(user: member).tutorial)
          .to eq(tutorial)
      end

      # Three hundred rows made one by one would be three hundred commits,
      # each recomputing a performance record; here they are one statement.
      it "seeds the group's rows in one statement, recomputing nothing" do
        create(:tutorial_membership, tutorial: tutorial, user: create(:confirmed_user))
        inserts = 0
        callback = lambda { |*, payload|
          inserts += 1 if payload[:sql].start_with?("INSERT INTO \"assessment_participations\"")
        }
        expect(StudentPerformance::ComputationService).not_to receive(:new)

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          render_inline(component)
        end

        expect(inserts).to eq(1)
        expect(assessment.assessment_participations.count).to eq(2)
      end

      # The row was made when the old group's tutor looked at the table; the
      # student moved before writing anything. Kept with the old group, the
      # new tutor would find the row locked as "held by" a group that has
      # nothing of theirs.
      it "hands a blank row to the group the student is in now" do
        old_group = create(:tutorial, lecture: lecture, title: "Old group")
        row = create(:assessment_participation, assessment: assessment, user: member,
                                                tutorial: old_group)

        page = render_inline(component)

        expect(row.reload.tutorial).to eq(tutorial)
        expect(page.text).not_to include(I18n.t("assessment.grading_tutorial.held_by",
                                                tutorial: "Old group"))
        expect(page.css("input[type=number]")).to be_present
      end

      it "hands on a row whose points were taken back again, nil task points and all" do
        assignment.update!(test_week: Time.zone.today.beginning_of_week.iso8601)
        old_group = create(:tutorial, lecture: lecture, title: "Old group")
        row = create(:assessment_participation, assessment: assessment, user: member,
                                                tutorial: old_group)
        create(:assessment_task_point, task: assessment.tasks.first,
                                       assessment_participation: row, points: nil)

        render_inline(described_class.new(assignment: assignment.reload, grading_scope: tutorial))

        expect(row.reload.tutorial).to eq(tutorial)
      end

      it "keeps a row something was written on where that was" do
        old_group = create(:tutorial, lecture: lecture, title: "Old group")
        row = create(:assessment_participation, assessment: assessment, user: member,
                                                tutorial: old_group, submitted_at: 1.hour.ago)

        render_inline(component)

        expect(row.reload.tutorial).to eq(old_group)
      end

      # After the week the old group's page still lists somebody who moved
      # away and left a blank row; the row goes to the group they are in now,
      # and the old group's tutor finds it held there.
      it "hands a blank row on to the new group from the old group's page too" do
        # rubocop:disable Rails/SkipsModelValidations
        assignment.update_column(:deadline, 1.week.ago.end_of_week)
        # rubocop:enable Rails/SkipsModelValidations
        new_group = create(:tutorial, lecture: lecture, title: "New group")
        row = create(:assessment_participation, assessment: assessment, user: member,
                                                tutorial: tutorial)
        TutorialMembership.where(user: member).destroy_all
        create(:tutorial_membership, tutorial: new_group, user: member)

        page = render_inline(described_class.new(assignment: assignment.reload,
                                                 grading_scope: tutorial))

        expect(row.reload.tutorial).to eq(new_group)
        expect(page.text).to include(I18n.t("assessment.grading_tutorial.held_by",
                                            tutorial: "New group"))
      end

      it "hands a blank row to no group when the student left every group" do
        row = create(:assessment_participation, assessment: assessment, user: member,
                                                tutorial: tutorial)
        create(:lecture_membership, lecture: lecture, user: member)
        TutorialMembership.where(user: member).destroy_all

        render_inline(described_class.new(assignment: assignment, grading_scope: lecture))

        expect(row.reload.tutorial).to be_nil
      end

      # What this page read as blank may have been marked since; the write
      # looks again under the lock the marking took.
      it "leaves a row alone that was marked since the page read it" do
        assignment.update!(test_week: Time.zone.today.beginning_of_week.iso8601)
        old_group = create(:tutorial, lecture: lecture, title: "Old group")
        row = create(:assessment_participation, assessment: assessment, user: member,
                                                tutorial: old_group)
        allow_any_instance_of(Assessment::Participation).to receive(:with_lock) do |locked, &block|
          locked.update!(submitted_at: Time.current)
          block.call
        end

        render_inline(described_class.new(assignment: assignment.reload, grading_scope: tutorial))

        expect(row.reload.tutorial).to eq(old_group)
      end

      it "offers to take an absence back whatever the week says" do
        create(:assessment_participation, assessment: assessment, user: member,
                                          tutorial: tutorial, status: :absent)
        label = I18n.t("assessment.grading_exam.remove_absent")

        expect(render_inline(component).css("a[aria-label='#{label}']")).to be_present
      end

      it "offers to record an absence once the week has begun, not before" do
        label = I18n.t("assessment.grading_exam.mark_absent")
        expect(render_inline(component).css("a[aria-label='#{label}']")).to be_empty

        assignment.update!(test_week: Time.zone.today.beginning_of_week.iso8601)
        fresh = described_class.new(assignment: assignment.reload, grading_scope: tutorial)

        expect(render_inline(fresh).css("a[aria-label='#{label}']")).to be_present
      end

      it "leaves the test deletable, the rows it made carrying nothing yet" do
        render_inline(component)

        expect(assignment.reload).to be_destructible
      end

      it "counts no hand-ins and draws no file columns" do
        page = render_inline(component)

        expect(page.css("#marking-summary").text).not_to include("handed in")
        expect(page.css("th").map(&:text).join).not_to include(I18n.t("basics.submission"))
      end
    end

    context "when the assignment has no assessment" do
      let!(:assignment) { create(:assignment, :without_assessment, lecture: lecture) }
      let!(:assessment) { nil }
      let(:member) { create(:confirmed_user) }

      before do
        allow(vc_test_controller).to receive(:current_user).and_return(lecture.teacher)
        create(:tutorial_membership, tutorial: tutorial, user: member)
      end

      it "has no rows without a file" do
        expect(component.rows?).to be(false)
      end

      it "draws the files and the downloads, and no roster row" do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [create(:confirmed_user)])
        rendered = render_inline(component)

        expect(rendered.css("tr[id^=participation-row]")).to be_empty
        expect(rendered.text).to include(I18n.t("submission.bulk_download_submissions"))
        expect(rendered.text).not_to include(I18n.t("assessment.grading_tutorial.save_all"))
        expect(rendered.text)
          .not_to include(I18n.t("assessment.grading_tutorial.blank_points_hint"))
      end
    end

    describe "#row_statuses" do
      let(:member) { create(:confirmed_user) }
      let(:partner) { create(:confirmed_user) }

      it "reads a team row the way the row reads itself, once per member" do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [member, partner])
        Timecop.travel(3.hours.from_now) do
          create(:assessment_participation, :reviewed, assessment: assessment, user: partner,
                                                       tutorial: tutorial)
          expect(component.row_statuses).to eq([:reviewed, :reviewed])
        end
      end

      it "counts people and names the teams in the summary" do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [member, partner])
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [create(:confirmed_user)])

        text = I18n.with_locale(:en) { render_inline(component.summary).text }
        expect(text).to include("3 handed in (2 teams)")
      end

      it "names no team behind a file the tutor refused" do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [member, partner], accepted: false)
        [member, partner].each do |user|
          create(:assessment_participation, assessment: assessment, user: user,
                                            tutorial: tutorial, submitted_at: nil)
        end
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [create(:confirmed_user)])

        text = I18n.with_locale(:en) { render_inline(component.summary).text }
        expect(text).to include("1 handed in")
        expect(text).not_to include("team")
      end

      it "leaves the teams out when everybody handed in alone" do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [member])

        text = I18n.with_locale(:en) { render_inline(component.summary).text }
        expect(text).to include("1 handed in")
        expect(text).not_to include("team")
      end

      it "reads a file without any participation as still to be marked" do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [member])

        expect(component.row_statuses).to eq([:pending_grading])
      end

      it "reads somebody without a hand-in off their unsaved row" do
        create(:tutorial_membership, tutorial: tutorial, user: member)

        expect(component.row_statuses).to eq([:not_submitted])
      end
    end

    describe "#participation_for" do
      let(:member) { create(:confirmed_user) }

      it "is the participation on file" do
        participation = create(:assessment_participation, assessment: assessment, user: member,
                                                          tutorial: tutorial)
        allow(assignment).to receive(:non_submitters_in_tutorial).and_return(User.where(id: member))

        expect(component.participation_for(member, tutorial)).to eq(participation)
      end

      it "is an unsaved one for the group otherwise" do
        built = component.participation_for(member, tutorial)

        expect(built).to be_new_record
        expect(built.user).to eq(member)
        expect(built.tutorial).to eq(tutorial)
      end
    end

    describe "rendering" do
      it "renders the grading table" do
        render_inline(component)
        expect(rendered_content).to include("marking-table")
      end
    end

    describe "a team another tutorial marks" do
      let(:member) { create(:confirmed_user) }
      let(:other_tutorial) { create(:tutorial, lecture: lecture) }
      let!(:team) do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: other_tutorial,
                                              users: [member, create(:confirmed_user)])
      end

      before { create(:tutorial_membership, tutorial: tutorial, user: member) }

      it "shows the row of the member who sits here" do
        allow(vc_test_controller).to receive(:current_user).and_return(create(:confirmed_user))

        render_inline(component)

        expect(rendered_content).to include("submission-row-#{team.id}")
      end

      it "leaves it to the marking tutorial's summary" do
        expect(component.row_statuses).to be_empty
      end
    end
  end

  describe "when grading_scope is a Lecture" do
    let(:component) do
      described_class.new(assignment: assignment, grading_scope: lecture)
    end

    describe "initialization" do
      it "sets @lecture from the assignment's lecture" do
        expect(component.instance_variable_get(:@lecture)).to eq(assignment.lecture)
      end

      it "sets @tutorials from the lecture's tutorials" do
        tutorial
        expect(component.instance_variable_get(:@tutorials)).to include(tutorial)
      end

      it "groups submissions by tutorial" do
        submission = create(:submission, :with_manuscript,
                            assignment: assignment,
                            tutorial: tutorial,
                            users: [create(:confirmed_user)])
        assignment.reload
        grouped = described_class.new(assignment: assignment, grading_scope: lecture)
                                 .instance_variable_get(:@submissions_by_tutorial)
        expect(grouped[tutorial]).to include(submission)
      end

      # A row with a hand-in on it stays with its group whatever the roster
      # says; a blank one would follow the roster.
      it "groups non-submitters by tutorial via their preloaded participation" do
        user = create(:confirmed_user)
        participation = create(:assessment_participation, assessment: assessment, user: user,
                                                          tutorial: tutorial,
                                                          submitted_at: 1.day.ago)
        allow(assignment).to receive(:non_submitters_in_tutorials).and_return(User.where(id: user))

        grouped = described_class.new(assignment: assignment, grading_scope: lecture)
                                 .instance_variable_get(:@non_submitters_by_tutorial)
        expect(grouped[tutorial]).to include(user)
        participation # keep reference so rubocop doesn't flag unused let
      end
    end

    describe "rendering" do
      it "renders the grading table" do
        render_inline(component)
        expect(rendered_content).to include("marking-table")
      end
    end

    context "with somebody who left during a test's week" do
      let!(:assignment) do
        create(:assignment, :with_lecture, lecture: lecture, kind: :test,
                                           deadline: Time.zone.now.end_of_week)
      end
      let(:former) { create(:confirmed_user, name_in_tutorials: "Lina Berg") }

      before do
        allow(vc_test_controller).to receive(:current_user).and_return(lecture.teacher)
        create(:lecture_membership, lecture: lecture, user: former).exclude!(by: former)
        create(:assessment_participation, assessment: assessment, user: former,
                                          tutorial: tutorial, points_total: 4,
                                          status: :reviewed)
      end

      it "lists their marked row before the deadline, for the lecturer and the old tutor" do
        [lecture, tutorial].each do |scope|
          rows = render_inline(described_class.new(assignment: assignment.reload,
                                                   grading_scope: scope)).css("tr")

          expect(rows.find { |tr| tr.text.include?("Lina Berg") }&.text)
            .to include(I18n.t("assessment.grading_tutorial.left_lecture")), scope.class.name
        end
      end

      # Points entered and taken back again leave a task point of nothing
      # behind: the row is blank, and no group would hold it once listed.
      it "lists a row by its points, not by task points of nothing" do
        task = create(:assessment_task, assessment: assessment)
        { "Mia Roth" => nil, "Ben Ott" => 3 }.each do |name, points|
          former = create(:confirmed_user, name_in_tutorials: name)
          create(:lecture_membership, lecture: lecture, user: former).exclude!(by: former)
          row = create(:assessment_participation, assessment: assessment, user: former,
                                                  tutorial: tutorial)
          create(:assessment_task_point, assessment_participation: row, task: task,
                                         points: points)
        end

        text = render_inline(described_class.new(assignment: assignment.reload,
                                                 grading_scope: tutorial)).text

        expect(text).to include("Ben Ott")
        expect(text).not_to include("Mia Roth")
      end
    end

    context "with somebody who left the lecture" do
      let(:former) { create(:confirmed_user, name_in_tutorials: "Lina Berg") }

      before do
        allow(vc_test_controller).to receive(:current_user).and_return(lecture.teacher)
        assignment.update_column(:deadline, 2.days.ago) # rubocop:disable Rails/SkipsModelValidations
        create(:lecture_membership, lecture: lecture, user: former).exclude!(by: former)
      end

      it "lists their work that no tutorial holds, saying they left" do
        create(:assessment_participation, assessment: assessment, user: former,
                                          tutorial: nil, submitted_at: 3.days.ago)

        rows = render_inline(described_class.new(assignment: assignment.reload,
                                                 grading_scope: lecture)).css("tr")

        expect(rows.find { |row| row.text.include?("Lina Berg") }&.text)
          .to include(I18n.t("assessment.grading_tutorial.left_lecture"))
      end

      it "leaves out a blank row of theirs" do
        create(:assessment_participation, assessment: assessment, user: former, tutorial: nil)

        rendered = render_inline(described_class.new(assignment: assignment.reload,
                                                     grading_scope: lecture))

        expect(rendered.text).not_to include("Lina Berg")
      end

      it "keeps their hand-in as it was, with no button to take it back" do
        create(:assessment_participation, assessment: assessment, user: former,
                                          tutorial: nil, submitted_at: 3.days.ago)

        rows = render_inline(described_class.new(assignment: assignment.reload,
                                                 grading_scope: lecture)).css("tr")
        row = rows.find { |tr| tr.text.include?("Lina Berg") }

        kept = I18n.t("assessment.grading_tutorial.paper_hand_in_kept")
        expect(row.css("[aria-label='#{kept}']")).to be_present
        expect(row.css("a[data-turbo-method='patch']")).to be_empty
      end

      it "does not offer them for a team, which takes only the tutorial's members" do
        create(:assessment_participation, assessment: assessment, user: former,
                                          tutorial: tutorial, submitted_at: 3.days.ago)
        submission = create(:submission, :with_manuscript, assignment: assignment,
                                                           tutorial: tutorial,
                                                           users: [create(:confirmed_user)])
        create(:tutorial_membership, tutorial: tutorial,
                                     user: create(:confirmed_user, name_in_tutorials: "Max Kurz"))

        rendered = render_inline(described_class.new(assignment: assignment.reload,
                                                     grading_scope: tutorial))
        path = Rails.application.routes.url_helpers.add_member_submission_path(submission)
        offered = rendered.css("form[action='#{path}']").map(&:text).join

        expect(offered).to include("Max Kurz")
        expect(offered).not_to include("Lina Berg")
      end

      it "asks once who has left, however many rows the table has" do
        members = create_list(:confirmed_user, 3)
        members.each do |member|
          create(:tutorial_membership, tutorial: tutorial, user: member)
          create(:assessment_participation, assessment: assessment, user: member,
                                            tutorial: tutorial, submitted_at: 3.days.ago)
        end
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [create(:confirmed_user)])
        lookups = 0
        callback = lambda { |*, payload|
          lookups += 1 if payload[:sql].start_with?('SELECT "lecture_memberships"."user_id"') &&
                          payload[:sql].include?('"excluded_at" IS NOT NULL')
        }

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          render_inline(described_class.new(assignment: assignment.reload,
                                            grading_scope: tutorial))
        end

        expect(lookups).to eq(1)
      end

      it "says so in the old tutorial's table too" do
        create(:assessment_participation, assessment: assessment, user: former,
                                          tutorial: tutorial, submitted_at: 3.days.ago)

        rows = render_inline(described_class.new(assignment: assignment.reload,
                                                 grading_scope: tutorial)).css("tr")

        expect(rows.find { |row| row.text.include?("Lina Berg") }&.text)
          .to include(I18n.t("assessment.grading_tutorial.left_lecture"))
      end
    end
  end

  describe "#preload_participations" do
    let(:component) do
      described_class.new(assignment: assignment, grading_scope: tutorial)
    end
    let(:user) { create(:confirmed_user) }
    let(:submitter) { create(:confirmed_user) }
    let!(:participation) do
      create(:assessment_participation, assessment: assessment, user: user, tutorial: tutorial)
    end
    let!(:submitter_participation) do
      create(:assessment_participation, assessment: assessment, user: submitter,
                                        tutorial: tutorial)
    end
    let(:submission) do
      create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                            users: [submitter])
    end

    it "returns a hash keyed by user_id, submitters and non-submitters alike" do
      result = component.preload_participations([user], [submission], { user.id => tutorial })

      expect(result[user.id]).to eq(participation)
      expect(result[submitter.id]).to eq(submitter_participation)
    end

    it "preloads task_points so no further query is issued" do
      preloaded = component.preload_participations([user], [], { user.id => tutorial })[user.id]
      query_count = 0
      callback = lambda { |*, payload|
        query_count += 1 unless payload[:sql].match?(/SCHEMA|TRANSACTION/)
      }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        preloaded.task_points.to_a
      end
      expect(query_count).to eq(0)
    end

    it "hands a submission row the participations of its team" do
      submission
      built = described_class.new(assignment: assignment, grading_scope: tutorial)

      expect(built.team_participations(submission)).to eq([submitter_participation])
    end
  end
end
