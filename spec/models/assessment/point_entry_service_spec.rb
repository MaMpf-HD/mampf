require "rails_helper"

RSpec.describe(Assessment::PointEntryService, type: :model) do
  let(:assessment) { FactoryBot.create(:assessment, :gradable, requires_points: true) }
  let(:task1) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10) }
  let(:task2) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 5) }
  let(:participation) { FactoryBot.create(:assessment_participation, assessment: assessment) }
  let(:grader) { FactoryBot.create(:confirmed_user) }

  describe ".enter_points" do
    context "when the assessment does not require points" do
      let(:assessment_no_points) do
        FactoryBot.create(:assessment, :gradable, requires_points: false)
      end
      let(:participation_no_points) do
        FactoryBot.create(:assessment_participation, assessment: assessment_no_points)
      end

      it "raises ArgumentError" do
        expect do
          described_class.enter_points(participation_no_points, {}, grader)
        end.to raise_error(ArgumentError, /does not accept points/)
      end
    end

    context "with valid task ids" do
      # ensure tasks are created before entering points
      before do
        task1
        task2
      end
      it "creates task points for each task" do
        expect do
          described_class.enter_points(participation, { task1.id => "8", task2.id => "4" }, grader)
        end.to change(Assessment::TaskPoint, :count).by(2)
      end

      it "persists the correct point values" do
        described_class.enter_points(participation, { task1.id => "7.5", task2.id => "3" }, grader)

        tp1 = Assessment::TaskPoint.find_by(task_id: task1.id,
                                            assessment_participation_id: participation.id)
        tp2 = Assessment::TaskPoint.find_by(task_id: task2.id,
                                            assessment_participation_id: participation.id)

        expect(tp1.points).to eq(7.5)
        expect(tp2.points).to eq(3.0)
      end

      it "assigns the grader to each task point" do
        described_class.enter_points(participation, { task1.id => "5" }, grader)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.grader).to eq(grader)
      end

      it "returns the participation" do
        result = described_class.enter_points(participation, { task1.id => "5" }, grader)
        expect(result).to eq(participation)
      end

      it "calls recompute_points_total! on participation" do
        expect(participation).to receive(:recompute_points_total!)
        described_class.enter_points(participation, { task1.id => "5" }, grader)
      end

      it "calls update_status_if_all_scored! on participation" do
        expect(participation).to receive(:update_status_if_all_scored!)
        described_class.enter_points(participation, { task1.id => "5" }, grader)
      end
    end

    context "with an invalid task id" do
      it "raises ArgumentError" do
        expect do
          described_class.enter_points(participation, { 999_999 => "5" }, grader)
        end.to raise_error(ArgumentError, /Invalid task/)
      end

      it "does not persist any task points (rolls back transaction)" do
        expect do
          described_class.enter_points(participation, { task1.id => "5", 999_999 => "3" }, grader)
        rescue ArgumentError
          nil
        end.not_to change(Assessment::TaskPoint, :count)
      end
    end

    context "with nil points (unscoring)" do
      before { task1 }

      it "saves a task point with nil points" do
        described_class.enter_points(participation, { task1.id => nil }, grader)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.points).to be_nil
      end
    end

    context "with an empty string as points" do
      before { task1 }

      it "saves a task point with nil points" do
        described_class.enter_points(participation, { task1.id => "" }, grader)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.points).to be_nil
      end
    end

    context "with numeric (non-string) points" do
      before { task1 }

      it "accepts an integer" do
        described_class.enter_points(participation, { task1.id => 8 }, grader)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.points).to eq(8.0)
      end

      it "accepts a float" do
        described_class.enter_points(participation, { task1.id => 7.5 }, grader)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.points).to eq(7.5)
      end
    end

    context "with an invalid points string" do
      before { task1 }

      it "raises ArgumentError for a non-numeric string" do
        expect do
          described_class.enter_points(participation, { task1.id => "abc" }, grader)
        end.to raise_error(ArgumentError, /Invalid points value for task/)
      end

      it "rolls back the transaction on invalid points" do
        task2 # ensure created

        expect do
          # task1 gets valid points, task2 gets invalid — whole transaction should roll back
          described_class.enter_points(participation,
                                       { task1.id => "5", task2.id => "bad" },
                                       grader)
        rescue ArgumentError
          nil
        end.not_to change(Assessment::TaskPoint, :count)
      end
    end

    context "with a non-Numeric, non-String points value" do
      before { task1 }

      it "raises ArgumentError for an array" do
        expect do
          described_class.enter_points(participation, { task1.id => [5] }, grader)
        end.to raise_error(ArgumentError, /Invalid points value for task/)
      end

      it "raises ArgumentError for a hash" do
        expect do
          described_class.enter_points(participation, { task1.id => { value: 5 } }, grader)
        end.to raise_error(ArgumentError, /Invalid points value for task/)
      end
    end

    context "with bonus points exceeding task max_points" do
      before { task1 }

      it "saves the bonus points without error" do
        described_class.enter_points(participation, { task1.id => "15" }, grader)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.points).to eq(15.0)
      end
    end

    context "when updating existing task points (find_or_initialize_by)" do
      before { task1 }

      it "updates rather than duplicates an existing task point" do
        described_class.enter_points(participation, { task1.id => "5" }, grader)

        expect do
          described_class.enter_points(participation, { task1.id => "9" }, grader)
        end.not_to change(Assessment::TaskPoint, :count)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.points).to eq(9.0)
      end
    end

    context "with a submission" do
      let(:submission) { FactoryBot.create(:assessment_task_point, :with_submission).submission }

      before { task1 }

      it "assigns the submission id to the task point" do
        described_class.enter_points(participation, { task1.id => "6" }, grader, submission)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.submission_id).to eq(submission.id)
      end
    end

    context "without a submission" do
      before { task1 }

      it "leaves submission_id as nil" do
        described_class.enter_points(participation, { task1.id => "6" }, grader)

        tp = Assessment::TaskPoint.find_by(task_id: task1.id,
                                           assessment_participation_id: participation.id)
        expect(tp.submission_id).to be_nil
      end
    end

    context "with an empty task_points hash" do
      it "makes no task point changes but still recomputes totals" do
        expect(participation).to receive(:recompute_points_total!)
        expect(participation).to receive(:update_status_if_all_scored!)

        expect do
          described_class.enter_points(participation, {}, grader)
        end.not_to change(Assessment::TaskPoint, :count)
      end
    end
  end
end
