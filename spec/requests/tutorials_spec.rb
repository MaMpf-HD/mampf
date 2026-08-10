require "rails_helper"

RSpec.describe("Tutorials", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:tutor) { create(:confirmed_user) }
  let!(:tutorial) { create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id, lecture: lecture) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "GET /lectures/:id/tutorials" do
    let(:assignment) { create(:assignment, lecture: lecture, accepted_file_type: ".pdf") }

    context "when feature flag enabled" do
      before do
        Flipper.enable(:roster_maintenance)
        Flipper.enable(:registration_campaigns)
        # The submission rows only render their action menu for a tutor of the
        # group, and #index lists submissions that carry a manuscript.
        tutorial.tutors << editor
        5.times do
          student = create(:confirmed_user)
          create(:tutorial_membership, tutorial: tutorial, user: student)
          create(:submission, :with_manuscript, assignment: assignment,
                                                tutorial: tutorial).users << student
        end
        sign_in editor
      end

      after do
        Flipper.disable(:roster_maintenance)
        Flipper.disable(:registration_campaigns)
      end

      it "queries roster_eligible_tutorials? once per lecture across all submission rows" do
        expect_any_instance_of(Lecture).to receive(:roster_eligible_tutorials?)
          .once.and_call_original

        get lecture_tutorials_path(lecture, params: { tutorial: tutorial.id })

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /tutorials/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /tutorials" do
    let(:valid_attributes) { { title: "New Tutorial", capacity: 25, lecture_id: lecture.id } }
    let(:invalid_attributes) { { title: "", capacity: -1, lecture_id: lecture.id } }

    context "as an editor" do
      before { sign_in editor }

      context "with valid parameters" do
        it "creates a new tutorial" do
          expect do
            post(tutorials_path,
                 params: { tutorial: valid_attributes },
                 as: :turbo_stream)
          end.to change(Tutorial, :count).by(1)
        end

        it "renders a successful response" do
          post tutorials_path,
               params: { tutorial: valid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end

      context "with invalid parameters" do
        it "does not create a new tutorial" do
          expect do
            post(tutorials_path,
                 params: { tutorial: invalid_attributes },
                 as: :turbo_stream)
          end.not_to change(Tutorial, :count)
        end

        it "renders an unprocessable_entity response" do
          post tutorials_path,
               params: { tutorial: invalid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "GET /tutorials/:id/edit" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get edit_tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /tutorials/:id" do
    let(:valid_attributes) { { title: "Updated Tutorial", capacity: 30 } }
    let(:invalid_attributes) { { title: "", capacity: -1 } }

    context "as an editor" do
      before { sign_in editor }

      context "with valid parameters" do
        it "updates the requested tutorial" do
          patch tutorial_path(tutorial),
                params: { tutorial: valid_attributes },
                as: :turbo_stream
          tutorial.reload
          expect(tutorial.title).to eq("Updated Tutorial")
        end

        it "renders a successful response" do
          patch tutorial_path(tutorial),
                params: { tutorial: valid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end

      context "with invalid parameters" do
        it "does not update the tutorial" do
          patch tutorial_path(tutorial),
                params: { tutorial: invalid_attributes },
                as: :turbo_stream
          tutorial.reload
          expect(tutorial.title).not_to eq("")
        end

        it "renders an unprocessable_entity response" do
          patch tutorial_path(tutorial),
                params: { tutorial: invalid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "DELETE /tutorials/:id" do
    context "as an editor" do
      before { sign_in editor }

      it "destroys the requested tutorial" do
        expect do
          delete(tutorial_path(tutorial), as: :turbo_stream)
        end.to change(Tutorial, :count).by(-1)
      end

      it "renders a successful response" do
        delete tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end
  end

  describe "GET /tutorials/:id" do
    # let!(:other_tutorial) { create(:tutorial, lecture: lecture) }
    let(:students) { create_list(:confirmed_user, 5) }
    let!(:assignment) { create(:assignment, lecture: lecture, deadline: 1.hour.from_now) }
    let!(:submissions) do
      students.each do |student|
        create(:submission, :with_manuscript,
               assignment: assignment,
               tutorial: tutorial,
               users: [student])
      end
    end

    before do
      Flipper.enable(:registration_campaigns)
      Flipper.enable(:roster_maintenance)
      students.each { |student| create(:tutorial_membership, tutorial: tutorial, user: student) }
      Timecop.travel(2.hours.from_now)
    end

    after do
      Timecop.return
      Flipper.disable(:registration_campaigns)
      Flipper.disable(:roster_maintenance)
    end

    context "as a tutor" do
      before { sign_in tutor }

      it "queries roster_eligible_tutorials? once per lecture, not once per submission row" do
        expect_any_instance_of(Lecture).to receive(:roster_eligible_tutorials?)
          .once.and_call_original

        get lecture_tutorials_path(lecture),
            as: :turbo_stream
      end

      it "renders successfully" do
        get lecture_tutorials_path(lecture), as: :turbo_stream

        expect(response).to have_http_status(:success)
      end
    end
  end
end
