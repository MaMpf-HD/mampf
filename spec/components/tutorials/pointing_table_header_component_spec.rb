require "rails_helper"

RSpec.describe(PointingTableHeaderComponent, type: :component) do
  def columns_for(component)
    render_inline(component)
    component.columns
  end

  describe "#columns" do
    context "when mode is tutor" do
      let(:component) do
        described_class.new(mode: "tutor", grading_enabled: false)
      end

      it "always includes the team column" do
        expect(columns_for(component).map(&:css_class)).to include(a_string_matching(/team-col/))
      end

      it "does not include a tutorial column" do
        expect(columns_for(component).map(&:css_class))
          .not_to include(a_string_matching(/tutorial-col/))
      end

      it "includes the action column" do
        expect(columns_for(component).map(&:css_class))
          .to include(a_string_matching(/action-col/))
      end

      it "includes the correction column" do
        expect(columns_for(component).map(&:css_class))
          .to include(a_string_matching(/correction-col/))
      end
    end

    context "when mode is teacher" do
      let(:component) do
        described_class.new(mode: "teacher", grading_enabled: false)
      end

      it "includes a tutorial column" do
        expect(columns_for(component).map(&:css_class))
          .to include(a_string_matching(/tutorial-col/))
      end

      it "does not include the correction column" do
        expect(columns_for(component).map(&:css_class))
          .not_to include(a_string_matching(/correction-col/))
      end

      context "when no tutorials are given" do
        it "renders a plain tutorial column with no action_tag" do
          tutorial_col = columns_for(component).find { |c| c.css_class.include?("tutorial-col") }
          expect(tutorial_col.action_tag).to be_nil
        end

        it "does not add the z-20 class" do
          tutorial_col = columns_for(component).find { |c| c.css_class.include?("tutorial-col") }
          expect(tutorial_col.css_class).not_to include("z-20")
        end
      end

      context "when tutorials are given" do
        let(:tutorial) { build_stubbed(:tutorial) }
        let(:component) do
          described_class.new(mode: "teacher", grading_enabled: false, tutorials: [tutorial])
        end

        it "adds the filter-tutorials action_tag" do
          tutorial_col = columns_for(component).find { |c| c.css_class.include?("tutorial-col") }
          expect(tutorial_col.action_tag).to eq("filter-tutorials")
        end

        it "adds the z-20 class for stacking above the filter dropdown" do
          tutorial_col = columns_for(component).find { |c| c.css_class.include?("tutorial-col") }
          expect(tutorial_col.css_class).to include("z-20")
        end
      end
    end

    context "when grading_enabled is false" do
      let(:component) do
        described_class.new(mode: "tutor", grading_enabled: false)
      end

      it "does not include a status column" do
        expect(columns_for(component).map(&:css_class))
          .not_to include(a_string_matching(/status-col/))
      end

      it "does not include a total column" do
        expect(columns_for(component).map(&:css_class))
          .not_to include(a_string_matching(/total-col/))
      end

      it "does not include any task columns" do
        expect(columns_for(component).map(&:label)).not_to include(a_string_matching(/task/i))
      end
    end

    context "when grading_enabled is true" do
      let(:task) { build_stubbed(:assessment_task, position: 1, max_points: 10) }
      let(:component) do
        described_class.new(mode: "tutor", grading_enabled: true, tasks: [task],
                            total_max_points: 10)
      end

      it "includes a status column" do
        expect(columns_for(component).map(&:css_class)).to include(a_string_matching(/status-col/))
      end

      it "includes the filter-status action_tag on the status column" do
        status_column = columns_for(component).find { |c| c.css_class.include?("status-col") }
        expect(status_column.action_tag).to eq("filter-status")
      end

      it "includes one column per task" do
        expect(columns_for(component).map(&:css_class).count do |c|
          c.include?("task-col")
        end).to eq(1)
      end

      it "labels each task column with its position" do
        task_column = columns_for(component).find { |c| c.css_class.include?("task-col") }
        expect(task_column.label).to include("1")
      end

      it "shows the task's max_points in the sublabel" do
        task_column = columns_for(component).find { |c| c.css_class.include?("task-col") }
        expect(task_column.sublabel).to include("10")
      end

      it "includes a total column showing total_max_points in the sublabel" do
        total_column = columns_for(component).find { |c| c.css_class.include?("total-col") }
        expect(total_column.sublabel).to include("10")
      end

      it "includes the status column even in teacher mode (current behavior)" do
        teacher_component = described_class.new(mode: "teacher", grading_enabled: true)
        expect(columns_for(teacher_component).map(&:css_class))
          .to include(a_string_matching(/status-col/))
      end
    end

    context "when accepted_file_type is given" do
      let(:component) do
        described_class.new(mode: "tutor", grading_enabled: false, accepted_file_type: ".pdf")
      end

      it "shows the accepted file type in the correction column sublabel" do
        correction_column = columns_for(component).find do |c|
          c.css_class.include?("correction-col")
        end
        expect(correction_column.sublabel).to include(".pdf")
      end
    end

    context "when tasks is empty and total_max_points is 0" do
      let(:component) do
        described_class.new(mode: "tutor", grading_enabled: true)
      end

      it "still includes a total column" do
        expect(columns_for(component).map(&:css_class)).to include(a_string_matching(/total-col/))
      end

      it "shows 0 in the total column sublabel" do
        total_column = columns_for(component).find { |c| c.css_class.include?("total-col") }
        expect(total_column.sublabel).to include("0")
      end
    end
  end

  describe "rendering" do
    it "renders without error" do
      component = described_class.new(mode: "tutor", grading_enabled: true)
      expect { render_inline(component) }.not_to raise_error
    end
  end
end
