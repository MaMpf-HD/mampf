require "rails_helper"

RSpec.describe(TutorialPointingTableComponent, type: :component) do
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
        row = page.css("tr[id^=pointing-participation-row-]").first
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

      it "keeps a row something was written on where that was" do
        old_group = create(:tutorial, lecture: lecture, title: "Old group")
        row = create(:assessment_participation, assessment: assessment, user: member,
                                                tutorial: old_group, submitted_at: 1.hour.ago)

        render_inline(component)

        expect(row.reload.tutorial).to eq(old_group)
      end

      it "leaves the test deletable, the rows it made carrying nothing yet" do
        render_inline(component)

        expect(assignment.reload).to be_destructible
      end

      it "counts no hand-ins and draws no file columns" do
        page = render_inline(component)

        expect(page.css("#pointing-summary").text).not_to include("hand-in")
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
      end
    end

    describe "#row_statuses" do
      let(:member) { create(:confirmed_user) }
      let(:partner) { create(:confirmed_user) }

      it "reads a team row the way the row reads itself" do
        create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                              users: [member, partner])
        Timecop.travel(3.hours.from_now) do
          create(:assessment_participation, :reviewed, assessment: assessment, user: partner,
                                                       tutorial: tutorial)
          expect(component.row_statuses).to eq([:reviewed])
        end
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
        allow(assignment).to receive(:non_submitters_in_tutorial).and_return([member])

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
        expect(rendered_content).to include("pointing-table")
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

      it "groups non-submitters by tutorial via their preloaded participation" do
        user = create(:confirmed_user)
        participation = create(:assessment_participation, assessment: assessment, user: user,
                                                          tutorial: tutorial)
        allow(assignment).to receive(:non_submitters_in_tutorials).and_return([user])

        grouped = described_class.new(assignment: assignment, grading_scope: lecture)
                                 .instance_variable_get(:@non_submitters_by_tutorial)
        expect(grouped[tutorial]).to include(user)
        participation # keep reference so rubocop doesn't flag unused let
      end
    end

    describe "rendering" do
      it "renders the grading table" do
        render_inline(component)
        expect(rendered_content).to include("pointing-table")
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
