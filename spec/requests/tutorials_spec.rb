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

    # A test set up for next week has the latest deadline and nothing to do
    # on it yet; the page opens on the sheet whose marking is open.
    it "opens on the newest sheet whose marking is open, not on the one furthest ahead" do
      sheet = create(:assignment, :expired, lecture: lecture, title: "Sheet 3",
                                            expired_since: 2.days)
      create(:assignment, lecture: lecture, title: "Test next week", kind: :test,
                          deadline: 2.weeks.from_now)

      get lecture_tutorials_path(lecture, params: { tutorial: tutorial.id })

      selected = Nokogiri::HTML(response.body).at_css("#assignment-select option[selected]")
      expect(selected.text.strip).to eq(sheet.title)
    end

    it "shows the achievement asked for, and nothing of a sheet named beside it" do
      achievement = create(:achievement, :boolean, lecture: lecture, title: "Blackboard talk")

      get lecture_tutorials_path(lecture, params: { tutorial: tutorial.id,
                                                    achievement: achievement.id,
                                                    assignment: assignment.id })

      page = Nokogiri::HTML(response.body)
      expect(page.at_css("#assignment-select option[selected]").text.strip).to eq("Blackboard talk")
      expect(page.css("#bulk-upload-area")).to be_empty
      expect(page.css("tr.submission-row")).to be_empty
    end

    # A lecturer tutors no group of their own; the page opens on the lecture's
    # first one rather than on nothing.
    it "opens on the lecture's first group for a lecturer without one" do
      tutorial.tutors.delete(editor)

      get lecture_tutorials_path(lecture)

      expect(response).to have_http_status(:success)
      expect(Nokogiri::HTML(response.body).at_css("#tutorial-select")["value"])
        .to eq(tutorial.title)
    end

    it "says so when the lecture has no group at all" do
      bare = create(:lecture)
      create(:editable_user_join, user: editor, editable: bare)

      get lecture_tutorials_path(bare)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("tutorial.no_tutorials_yet").strip)
    end

    it "leaves an achievement without an assessment off the page" do
      achievement = create(:achievement, :boolean, lecture: lecture, title: "Old one")
      achievement.assessment.destroy!

      get lecture_tutorials_path(lecture, params: { tutorial: tutorial.id,
                                                    achievement: achievement.id })

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Old one")
    end

    it "does not draw another lecture's group, whatever the URL names" do
      achievement = create(:achievement, :boolean, lecture: lecture)
      foreign = create(:tutorial, lecture: create(:lecture))
      create(:tutorial_membership, tutorial: foreign, user: create(:confirmed_user,
                                                                   name_in_tutorials: "Ola"))

      get lecture_tutorials_path(lecture, params: { tutorial: foreign.id,
                                                    achievement: achievement.id })

      expect(response.body).not_to include("Ola")
      expect(achievement.assessment.assessment_participations.where(tutorial: foreign)).to be_empty
    end

    it "opens on the first sheet to come while none is open yet" do
      assignment.update!(deadline: 3.weeks.from_now)
      soon = create(:assignment, lecture: lecture, title: "Sheet 1", deadline: 1.week.from_now)

      get lecture_tutorials_path(lecture, params: { tutorial: tutorial.id })

      selected = Nokogiri::HTML(response.body).at_css("#assignment-select option[selected]")
      expect(selected.text.strip).to eq(soon.title)
    end
  end

  describe "the marking table's queries" do
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

  describe "GET /tutorials/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      # The title carries day and time, the location has a field of its own;
      # the form shows the pattern before anything is typed.
      it "shows what a title and a location look like" do
        get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream

        expect(response.body).to include(I18n.t("tutorial.title_placeholder"))
        expect(response.body).to include(I18n.t("tutorial.location_placeholder"))
      end

      # Whom the select offers is not obvious: only voucher holders, editors
      # and the teacher; the form says so and where the voucher is made.
      it "explains who can be picked as a tutor" do
        get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream

        info = ERB::Util.html_escape(I18n.t("tutorial.info.tutors"))
        expect(response.body).to include(info[0, 60])
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

      # A lecturer may make a student the tutor of their own group, but the
      # form asks first; the option says whom it would be about.
      it "marks a tutor candidate who is enrolled in the tutorial" do
        enrolled = create(:confirmed_user)
        create(:lecture_membership, lecture: lecture, user: enrolled)
        create(:tutorial_membership, tutorial: tutorial, user: enrolled)
        Redemption.create!(voucher: create(:voucher, :tutor, lecture: lecture), user: enrolled)

        get edit_tutorial_path(tutorial), as: :turbo_stream

        option = Nokogiri::HTML(response.body).at_css("option[value='#{enrolled.id}']")
        expect(option["data-enrolled"]).to eq("true")
        expect(response.body).to include("enrolled-tutor-guard")
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
