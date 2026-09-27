require "rails_helper"

RSpec.describe(MarkingTableHeaderComponent, type: :component) do
  let(:tutorial_scope) { build_stubbed(:tutorial) }
  let(:lecture_scope) { build_stubbed(:lecture) }
  let(:legacy_assignment) { build_stubbed(:assignment, accepted_file_type: ".pdf") }
  let(:assignment) do
    create(:assignment, :with_lecture).tap do |assignment|
      create(:assessment, requires_points: true, assessable: assignment,
                          lecture: assignment.lecture)
      assignment.reload
    end
  end

  def header(assessable, scope: tutorial_scope)
    layout = MarkingTableLayout.for(assessable: assessable, grading_scope: scope)
    described_class.new(assessable: assessable, layout: layout)
  end

  def columns_for(component)
    render_inline(component)
    component.columns
  end

  def classes_for(component)
    columns_for(component).map(&:css_class)
  end

  describe "a sheet's columns" do
    context "in a group's table" do
      let(:component) { header(legacy_assignment) }

      it "starts with the team" do
        expect(classes_for(component).first).to include("team-col")
      end

      it "has no tutorial column" do
        expect(classes_for(component)).not_to include(a_string_matching(/tutorial-col/))
      end

      it "names the hand-in column after the file it holds" do
        hand_in = columns_for(component).find { |c| c.css_class.include?("hand-in-col") }

        expect(hand_in.label).to eq(I18n.t("basics.submission"))
        expect(hand_in.sublabel).to include(".pdf")
      end

      it "has the correction column, without promising a file type" do
        correction = columns_for(component).find { |c| c.css_class.include?("correction-col") }

        expect(correction).to be_present
        expect(correction.sublabel).to be_nil
      end

      it "pins the team and the save column and nothing else" do
        sticky = classes_for(header(assignment)).select { |c| c.include?("sticky-col") }

        expect(sticky.map { |c| c[/sticky-col (\w+)-col/, 1] }).to eq(["team", "save"])
      end
    end

    context "in the lecture's table" do
      let(:component) { header(legacy_assignment, scope: lecture_scope) }

      it "has a tutorial column" do
        expect(classes_for(component)).to include(a_string_matching(/tutorial-col/))
      end

      it "has the correction column" do
        expect(classes_for(component)).to include(a_string_matching(/correction-col/))
      end
    end

    context "when the assignment has no assessment" do
      let(:component) { header(legacy_assignment) }

      it "has neither status, tasks, total nor save" do
        expect(classes_for(component))
          .not_to include(a_string_matching(/status-col|task-col|total-col|save-col/))
      end
    end

    context "when the assignment has an assessment with a task" do
      let!(:task) do
        create(:assessment_task, assessment: assignment.assessment, position: 1, max_points: 10)
      end
      let(:component) { header(assignment.reload) }

      it "has a status column" do
        expect(classes_for(component)).to include(a_string_matching(/status-col/))
      end

      it "has one column per task, labelled with position and maximum" do
        task_columns = columns_for(component).select { |c| c.css_class.include?("task-col") }

        expect(task_columns.size).to eq(1)
        expect(task_columns.first.label).to include("1")
        expect(task_columns.first.sublabel).to include("10")
      end

      # Two icons need no heading over them, but a screen reader still gets
      # one.
      it "puts the save column beside the total, with a heading only for readers" do
        classes = classes_for(component)
        save = columns_for(component).find { |c| c.css_class.include?("save-col") }
        total = columns_for(component).find { |c| c.css_class.include?("total-col") }

        expect(classes.index { |c| c.include?("save-col") })
          .to eq(classes.index { |c| c.include?("total-col") } + 1)
        expect(save.label_hidden).to be(true)
        expect(total.sublabel).to include("10")
      end
    end

    context "when the assessment has no tasks yet" do
      it "still has a total column, reading 0" do
        total = columns_for(header(assignment)).find { |c| c.css_class.include?("total-col") }

        expect(total.sublabel).to include("0")
      end
    end
  end

  describe "a talk's columns" do
    let(:seminar) { create(:lecture, :is_seminar) }
    let(:talk) do
      create(:talk, lecture: seminar).tap do |talk|
        create(:assessment, requires_points: false, assessable: talk, lecture: seminar)
        talk.reload
      end
    end
    let(:component) { header(talk, scope: seminar) }

    it "has the talk, grade, note and grading instead of tasks" do
      classes = classes_for(component)

      expect(classes).to include(a_string_matching(/talk-col/), a_string_matching(/grade-col/),
                                 a_string_matching(/note-col/), a_string_matching(/graded-col/))
      expect(classes)
        .not_to include(a_string_matching(/task-col|total-col|hand-in-col|correction-col/))
    end

    it "labels them, the person as the speaker" do
      columns = columns_for(component)
      labels = columns.map(&:label)

      expect(labels).to include(I18n.t("basics.talk"),
                                I18n.t("assessment.grade_talk_row.speaker"),
                                I18n.t("assessment.grade_talk_row.grade"),
                                I18n.t("assessment.grade_talk_row.graded"))
    end

    # Said once, in the heading, rather than in every row's empty field.
    it "says in the note heading who gets to read the note" do
      note = columns_for(component).find { |c| c.css_class.include?("note-col") }

      expect(note.label).to eq(I18n.t("assessment.grade_talk_row.note"))
      expect(note.sublabel).to be_nil
    end

    it "starts text headings at the left and centres the rest" do
      by_column = columns_for(component).to_h do |column|
        [column.css_class[/(\w[\w-]*)-col/, 1], column.css_class]
      end

      expect(by_column.slice("talk", "team", "note", "graded").values)
        .to all(satisfy { |css| css.exclude?("text-center") })
      expect(by_column.slice("status", "grade", "save").values).to all(include("text-center"))
    end

    it "pins the talk, the speaker and the save column" do
      sticky = classes_for(component).select { |c| c.include?("sticky-col") }

      expect(sticky.map { |c| c[/sticky-col (\w+)-col/, 1] }).to eq(["talk", "team", "save"])
    end
  end

  describe "rendering" do
    it "renders a sheet's header" do
      expect { render_inline(header(assignment)) }.not_to raise_error
    end
  end
end
