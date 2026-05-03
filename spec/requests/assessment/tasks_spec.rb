require "rails_helper"

RSpec.describe("Assessment::Tasks", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:assignment) { create(:valid_assignment, lecture: lecture) }
  let(:assessment) { assignment.assessment }

  before do
    Flipper.enable(:assessment_grading)
    sign_in teacher
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  describe "POST /assessment/assessments/:assessment_id/tasks" do
    context "with valid parameters" do
      it "creates a task" do
        expect do
          post(assessment_assessment_tasks_path(assessment),
               params: { assessment_task: { max_points: 7.5 } },
               as: :turbo_stream)
        end.to change(Assessment::Task, :count).by(1)
      end
    end

    context "with invalid parameters" do
      it "does not create a task" do
        expect do
          post(assessment_assessment_tasks_path(assessment),
               params: { assessment_task: { max_points: -1 } },
               as: :turbo_stream)
        end.not_to change(Assessment::Task, :count)
      end

      it "renders unprocessable_content" do
        post assessment_assessment_tasks_path(assessment),
             params: { assessment_task: { max_points: -1 } },
             as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("assessments_container")
      end
    end
  end

  describe "PATCH /assessment/assessments/:assessment_id/tasks/:id" do
    let!(:task) { create(:assessment_task, assessment: assessment, max_points: 3) }

    context "with valid parameters" do
      it "updates the task" do
        patch assessment_assessment_task_path(assessment, task),
              params: { assessment_task: { max_points: 4.5 } },
              as: :turbo_stream
        task.reload
        expect(task.max_points).to eq(4.5)
      end
    end

    context "with invalid parameters" do
      it "does not update the task" do
        patch assessment_assessment_task_path(assessment, task),
              params: { assessment_task: { max_points: -2 } },
              as: :turbo_stream
        task.reload
        expect(task.max_points).to eq(3)
      end

      it "renders unprocessable_content" do
        patch assessment_assessment_task_path(assessment, task),
              params: { assessment_task: { max_points: -2 } },
              as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(ActionView::RecordIdentifier.dom_id(task))
      end
    end
  end

  describe "DELETE /assessment/assessments/:assessment_id/tasks/:id" do
    let!(:task) { create(:assessment_task, assessment: assessment) }

    it "destroys the task" do
      expect do
        delete(assessment_assessment_task_path(assessment, task),
               as: :turbo_stream)
      end.to change(Assessment::Task, :count).by(-1)
    end
  end

  describe "POST /assessment/assessments/:assessment_id/tasks/reorder" do
    let!(:task1) { create(:assessment_task, assessment: assessment) }
    let!(:task2) { create(:assessment_task, assessment: assessment) }
    let!(:task3) { create(:assessment_task, assessment: assessment) }

    it "moves task to new position" do
      post reorder_assessment_assessment_tasks_path(assessment),
           params: { task_id: task3.id, position: 1 },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(task1.reload.position).to eq(2)
      expect(task2.reload.position).to eq(3)
      expect(task3.reload.position).to eq(1)
    end

    it "returns bad_request for non-existent task" do
      post reorder_assessment_assessment_tasks_path(assessment),
           params: { task_id: 99_999, position: 1 },
           as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end
end
