require "rails_helper"

RSpec.describe(AssessmentListItemComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  before do
    Flipper.enable(:assessment_grading)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  context "with an assignment" do
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }
    let(:component) { described_class.new(assessable: assignment, lecture: lecture) }

    it "renders the component" do
      render_inline(component)
      expect(rendered_content).to include(CGI.escapeHTML(assignment.title))
    end

    it "returns assignment as assessable_type" do
      expect(component.assessable_type).to eq(I18n.t("assessment.assignment"))
    end

    it "returns the correct show path" do
      render_inline(component)
      expect(component.show_path).to eq(
        Rails.application.routes.url_helpers.assessment_assessment_path(assessment.id)
      )
    end

    it "returns medium title when assignment has medium" do
      medium = create(:medium, :with_description, :with_editors,
                      teachable: lecture, released: "all", sort: "Script")
      assignment.update!(medium: medium)
      expect(component.medium_title).to eq(medium.local_title_for_viewers)
    end

    it "returns file type" do
      expect(component.file_type).to eq(assignment.accepted_file_type)
    end

    it "returns deletion date formatted" do
      expect(component.deletion_date).to eq(I18n.l(assignment.deletion_date, format: :long))
    end

    it "returns tasks count" do
      assessment.update!(requires_points: true)
      create(:assessment_task, assessment: assessment)
      create(:assessment_task, assessment: assessment)
      expect(component.tasks_count).to eq(2)
    end

    it "returns participations count" do
      student = create(:confirmed_user)
      create(:assessment_participation, assessment: assessment, user: student)
      expect(component.participations_count).to eq(1)
    end

    describe "badge_class and badge_text" do
      it "returns draft badge when results not published" do
        assessment.update!(results_published_at: nil)
        expect(component.badge_class).to eq("bg-warning text-dark")
        expect(component.badge_text).to eq(I18n.t("assessment.draft"))
      end

      it "returns success badge when results published" do
        assessment.update!(results_published_at: Time.current)
        expect(component.badge_class).to eq("bg-success")
        expect(component.badge_text).to eq(I18n.t("assessment.results_published"))
      end
    end

    describe "edit and delete paths for non-legacy assignments" do
      it "returns nil for edit_path" do
        expect(component.edit_path).to be_nil
      end

      it "returns nil for delete_path" do
        expect(component.delete_path).to be_nil
      end
    end
  end

  context "with a legacy assignment" do
    let(:assignment) do
      Flipper.disable(:assessment_grading)
      a = create(:valid_assignment, lecture: lecture)
      Flipper.enable(:assessment_grading)
      a
    end
    let(:component) { described_class.new(assessable: assignment, lecture: lecture, legacy: true) }

    it "renders legacy badge" do
      expect(component.badge_class).to eq("bg-secondary")
      expect(component.badge_text).to eq(I18n.t("assessment.legacy"))
    end

    it "returns edit path for legacy assignment" do
      render_inline(component)
      expect(component.edit_path).to eq(
        Rails.application.routes.url_helpers.edit_assignment_path(assignment)
      )
    end

    it "returns delete path for legacy assignment" do
      render_inline(component)
      expect(component.delete_path).to eq(
        Rails.application.routes.url_helpers.assignment_path(assignment)
      )
    end

    it "returns # as show_path when no assessment" do
      expect(component.show_path).to eq("#")
    end

    it "returns 0 for tasks_count when no assessment" do
      expect(component.tasks_count).to eq(0)
    end

    it "returns 0 for participations_count when no assessment" do
      expect(component.participations_count).to eq(0)
    end
  end

  context "without assessment" do
    let(:assignment) do
      Flipper.disable(:assessment_grading)
      a = create(:valid_assignment, lecture: lecture)
      Flipper.enable(:assessment_grading)
      a
    end
    let(:component) { described_class.new(assessable: assignment, lecture: lecture) }

    it "returns draft badge" do
      expect(component.badge_class).to eq("bg-warning text-dark")
      expect(component.badge_text).to eq(I18n.t("assessment.draft"))
    end

    it "returns # as show_path" do
      expect(component.show_path).to eq("#")
    end
  end

  context "with a talk" do
    let(:seminar) { create(:lecture, :released_for_all, sort: "seminar", teacher: teacher) }
    let(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }
    let(:speaker) { create(:confirmed_user) }
    let(:assessment) { talk.reload.assessment }
    let(:component) { described_class.new(assessable: talk, lecture: seminar) }

    before do
      create(:speaker_talk_join, talk: talk, speaker: speaker)
    end

    it "renders the component" do
      render_inline(component)
      expect(rendered_content).to include(talk.title)
    end

    it "returns talk as assessable_type" do
      expect(component.assessable_type).to eq(I18n.t("assessment.talk"))
    end

    it "returns speaker names" do
      another_speaker = create(:confirmed_user)
      create(:speaker_talk_join, talk: talk, speaker: another_speaker)
      expect(component.speaker_names).to include(speaker.name)
      expect(component.speaker_names).to include(another_speaker.name)
    end

    it "returns nil for speaker_names when no speakers" do
      talk.speakers.destroy_all
      expect(component.speaker_names).to be_nil
    end

    it "returns formatted talk date" do
      expect(component.talk_date).to eq(I18n.l(talk.dates.first, format: :long))
    end

    it "returns nil for talk_date when no dates" do
      talk.update!(dates: [])
      expect(component.talk_date).to be_nil
    end

    it "returns nil for medium_title" do
      expect(component.medium_title).to be_nil
    end

    it "returns nil for file_type" do
      expect(component.file_type).to be_nil
    end

    it "returns nil for deletion_date" do
      expect(component.deletion_date).to be_nil
    end

    it "returns 0 tasks_count for talk without tasks" do
      expect(component.tasks_count).to eq(0)
    end
  end
end
