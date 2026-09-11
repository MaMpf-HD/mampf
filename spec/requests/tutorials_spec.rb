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

    before do
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

    # The rows used to ask the lecture, per row, whether it ran a roster - for
    # a "move" button that existed only where it did not. Nothing asks now.
    it "lists the group's submissions without asking about the roster" do
      expect_any_instance_of(Lecture).not_to receive(:roster_managed?)

      get lecture_tutorials_path(lecture, params: { tutorial: tutorial.id })

      expect(response).to have_http_status(:success)
      expect(Nokogiri::HTML(response.body).css("tr.submission-row").size).to eq(5)
    end
  end

  describe "the pointing table's queries" do
    def count_queries
      count = 0
      subscription = ActiveSupport::Notifications
                     .subscribe("sql.active_record") do |*, payload|
        count += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION|CACHE/)
      end
      yield
      count
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    # A group of its own per measurement, every hand-in marked on every task,
    # so that a row asking per row for its team, its marks or its tasks shows
    # up in the count.
    def marked_group(hand_ins)
      built = create(:lecture, :released_for_all)
      group = create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id, lecture: built)
      assignment = create(:assignment, :expired, lecture: built, accepted_file_type: ".pdf")
      tasks = Array.new(3) do
        create(:assessment_task, assessment: assignment.assessment, max_points: 4)
      end
      hand_ins.times do
        student = create(:confirmed_user)
        create(:tutorial_membership, tutorial: group, user: student)
        create(:submission, :with_manuscript, assignment: assignment,
                                              tutorial: group).users << student
        participation = create(:assessment_participation,
                               assessment: assignment.assessment, user: student,
                               submitted_at: 2.days.ago)
        tasks.each do |task|
          create(:assessment_task_point, task: task, points: 2,
                                         assessment_participation: participation)
        end
      end
      [built, group, assignment]
    end

    def queries_for(hand_ins)
      built, group, assignment = marked_group(hand_ins)
      params = { tutorial: group.id, assignment: assignment.id }

      count_queries { get(lecture_tutorials_path(built, params: params)) }
    end

    it "does not grow with the number of hand-ins" do
      sign_in tutor

      expect(queries_for(8)).to eq(queries_for(2))
    end
  end

  # The page somebody lands on before there is anything: it used to be
  # unreachable, because the sidebar greyed the entry out exactly then.
  describe "GET /lectures/:id/tutorial_overview" do
    before { sign_in editor }

    it "offers the way to create the first group when there is none" do
      tutorial.destroy

      get lecture_tutorial_overview_path(lecture)

      expect(response.body).to include(I18n.t("lecture.no_tutorials_yet"))
      expect(response.body).to include(I18n.t("lecture.create_tutorials"))
      expect(response.body)
        .to include(CGI.escapeHTML(edit_lecture_path(lecture, tab: "groups")))
    end
  end

  describe "GET /tutorials/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      context "with a user who became a tutor by redeeming a voucher" do
        let(:redeemer) { create(:confirmed_user, name_in_tutorials: "Ada L.") }
        let!(:redemption) do
          Redemption.create!(voucher: create(:voucher, :tutor, lecture: lecture),
                             user: redeemer)
        end

        it "offers them in the tutor select, under their tutorial name" do
          get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream

          expect(response.body).to include("Ada L.")
        end

        it "stops offering them once the account is gone" do
          redeemer.destroy

          get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream

          expect(response.body).not_to include("Ada L.")
        end
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
end
