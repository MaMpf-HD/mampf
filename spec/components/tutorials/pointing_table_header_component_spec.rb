require "rails_helper"

RSpec.describe(PointingTableHeaderComponent, type: :component) do
  let(:tutorial_scope) { build_stubbed(:tutorial) }
  let(:lecture_scope) { build_stubbed(:lecture) }
  let(:layout) { PointingTableLayout.new(left: [:team], right: [:save]) }
  let(:legacy_assignment) { build_stubbed(:assignment, accepted_file_type: ".pdf") }
  let(:assignment) do
    create(:assignment, :with_lecture).tap do |assignment|
      create(:assessment, requires_points: true, assessable: assignment,
                          lecture: assignment.lecture)
      assignment.reload
    end
  end

  def header(assignment:, scope: tutorial_scope)
    described_class.new(assignment: assignment, grading_scope: scope, layout: layout)
  end

  def columns_for(component)
    render_inline(component)
    component.columns
  end

  def classes_for(component)
    columns_for(component).map(&:css_class)
  end

  describe "#columns" do
    context "when grading_scope is a Tutorial" do
      let(:component) { header(assignment: legacy_assignment) }

      it "always includes the team column" do
        expect(classes_for(component)).to include(a_string_matching(/team-col/))
      end

      it "does not include a tutorial column" do
        expect(classes_for(component)).not_to include(a_string_matching(/tutorial-col/))
      end

      it "includes the hand-in column, named after the file it holds" do
        hand_in = columns_for(component).find { |c| c.css_class.include?("hand-in-col") }

        expect(hand_in.label).to eq(I18n.t("basics.submission"))
      end

      # Two icons need no heading over them, but a screen reader still gets
      # one.
      it "puts the save column beside the total, with a heading only for readers" do
        component = header(assignment: assignment)
        classes = classes_for(component)
        save = columns_for(component).find { |c| c.css_class.include?("save-col") }

        expect(classes.index { |c| c.include?("save-col") })
          .to eq(classes.index { |c| c.include?("total-col") } + 1)
        expect(save.label_hidden).to be(true)
      end

      it "includes the correction column" do
        expect(classes_for(component)).to include(a_string_matching(/correction-col/))
      end
    end

    context "when grading_scope is a Lecture" do
      let(:component) { header(assignment: legacy_assignment, scope: lecture_scope) }

      it "includes a tutorial column" do
        expect(classes_for(component)).to include(a_string_matching(/tutorial-col/))
      end

      it "includes the correction column" do
        expect(classes_for(component)).to include(a_string_matching(/correction-col/))
      end
    end

    context "when the assignment has no assessment" do
      let(:component) { header(assignment: legacy_assignment) }

      it "does not include a status column" do
        expect(classes_for(component)).not_to include(a_string_matching(/status-col/))
      end

      it "does not include a total column" do
        expect(classes_for(component)).not_to include(a_string_matching(/total-col/))
      end

      it "does not include any task columns" do
        expect(columns_for(component).map(&:label)).not_to include(a_string_matching(/task/i))
      end
    end

    context "when the assignment has an assessment with a task" do
      let!(:task) do
        create(:assessment_task, assessment: assignment.assessment, position: 1, max_points: 10)
      end
      let(:component) { header(assignment: assignment.reload) }

      it "includes a status column" do
        expect(classes_for(component)).to include(a_string_matching(/status-col/))
      end

      it "includes one column per task" do
        expect(classes_for(component).count { |c| c.include?("task-col") }).to eq(1)
      end

      it "labels each task column with its position" do
        task_column = columns_for(component).find { |c| c.css_class.include?("task-col") }
        expect(task_column.label).to include("1")
      end

      it "shows the task's max_points in the sublabel" do
        task_column = columns_for(component).find { |c| c.css_class.include?("task-col") }
        expect(task_column.sublabel).to include("10")
      end

      it "includes a total column showing the sheet's maximum in the sublabel" do
        total_column = columns_for(component).find { |c| c.css_class.include?("total-col") }
        expect(total_column.sublabel).to include("10")
      end

      it "includes the status column in the lecture's table as well" do
        teacher_component = header(assignment: assignment.reload, scope: lecture_scope)
        expect(classes_for(teacher_component)).to include(a_string_matching(/status-col/))
      end
    end

    it "shows the accepted file type in the correction column sublabel" do
      correction_column = columns_for(header(assignment: legacy_assignment)).find do |c|
        c.css_class.include?("correction-col")
      end
      expect(correction_column.sublabel).to include(".pdf")
    end

    context "when the assessment has no tasks yet" do
      let(:component) { header(assignment: assignment) }

      it "still includes a total column" do
        expect(classes_for(component)).to include(a_string_matching(/total-col/))
      end

      it "shows 0 in the total column sublabel" do
        total_column = columns_for(component).find { |c| c.css_class.include?("total-col") }
        expect(total_column.sublabel).to include("0")
      end
    end

    context "when grading_scope is neither Tutorial nor Lecture" do
      let(:component) { header(assignment: legacy_assignment, scope: nil) }

      it "does not raise" do
        expect { columns_for(component) }.not_to raise_error
      end

      it "does not include a tutorial column (treated as tutor-like)" do
        expect(classes_for(component)).not_to include(a_string_matching(/tutorial-col/))
      end

      it "includes the correction column" do
        expect(classes_for(component)).to include(a_string_matching(/correction-col/))
      end
    end
  end

  describe "rendering" do
    it "renders without error" do
      expect { render_inline(header(assignment: assignment)) }.not_to raise_error
    end
  end
end
