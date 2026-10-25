require "rails_helper"

RSpec.describe("Cohorts", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let!(:cohort) { create(:cohort, context: lecture) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "GET /cohorts/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_cohort_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get new_cohort_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /cohorts" do
    let(:valid_attributes) { { title: "New Cohort", capacity: 20, lecture_id: lecture.id } }
    let(:invalid_attributes) { { title: "", capacity: -1, lecture_id: lecture.id } }

    context "as an editor" do
      before { sign_in editor }

      context "with valid parameters" do
        it "creates a new Cohort" do
          expect do
            post(cohorts_path,
                 params: { cohort: valid_attributes },
                 as: :turbo_stream)
          end.to change(Cohort, :count).by(1)
        end

        it "marks cohort as skip_campaigns in no_campaign section" do
          post(cohorts_path,
               params: {
                 cohort: valid_attributes,
                 registration_section: "no_campaign"
               },
               as: :turbo_stream)

          expect(Cohort.order(:id).last.skip_campaigns).to be(true)
        end

        it "renders a successful response" do
          post cohorts_path,
               params: { cohort: valid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end

      context "with invalid parameters" do
        it "does not create a new Cohort" do
          expect do
            post(cohorts_path,
                 params: { cohort: invalid_attributes },
                 as: :turbo_stream)
          end.not_to change(Cohort, :count)
        end

        it "renders an unprocessable_entity response" do
          post cohorts_path,
               params: { cohort: invalid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "does not create a new Cohort" do
        expect do
          post(cohorts_path,
               params: { cohort: valid_attributes },
               as: :turbo_stream)
        end.not_to change(Cohort, :count)
      end

      it "redirects to root (unauthorized)" do
        post cohorts_path,
             params: { cohort: valid_attributes },
             as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /cohorts/:id" do
    let(:new_attributes) { { title: "Updated Cohort", capacity: 30 } }

    context "as an editor" do
      before { sign_in editor }

      context "with valid parameters" do
        it "updates the requested cohort" do
          patch cohort_path(cohort),
                params: { cohort: new_attributes },
                as: :turbo_stream
          cohort.reload
          expect(cohort.title).to eq("Updated Cohort")
          expect(cohort.capacity).to eq(30)
        end

        it "renders a successful response" do
          patch cohort_path(cohort),
                params: { cohort: new_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:ok)
        end

        it "names the cohort's tutors" do
          tutor = create(:confirmed_user)

          patch cohort_path(cohort), params: { cohort: { tutor_ids: [tutor.id] } },
                                     as: :turbo_stream

          expect(cohort.reload.tutors).to contain_exactly(tutor)
        end
      end

      context "with invalid parameters" do
        it "renders an unprocessable_content response" do
          patch cohort_path(cohort),
                params: { cohort: { title: "" } },
                as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "does not update the cohort" do
        patch cohort_path(cohort),
              params: { cohort: new_attributes },
              as: :turbo_stream
        cohort.reload
        expect(cohort.title).not_to eq("Updated Cohort")
      end

      it "redirects to root (unauthorized)" do
        patch cohort_path(cohort),
              params: { cohort: new_attributes },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /cohorts/:id/confirm_destroy" do
    it "says how many members end up without a group" do
      sign_in editor
      2.times { cohort.add_user_to_roster!(create(:confirmed_user)) }

      get confirm_destroy_cohort_path(cohort), as: :turbo_stream

      body = CGI.unescapeHTML(response.body)
      expect(body).to include(I18n.t("roster.cohorts.destroy.members", count: 2))
      expect(body).to include(I18n.t("roster.cohorts.destroy.without_group", count: 2))
      expect(body).to include(I18n.t("roster.cohorts.destroy.notify"))
    end

    it "redirects a student to root (unauthorized)" do
      sign_in student

      get confirm_destroy_cohort_path(cohort), as: :turbo_stream

      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /cohorts/:id" do
    context "as an editor" do
      before { sign_in editor }

      context "with members" do
        let(:member) { create(:confirmed_user) }

        before { cohort.add_user_to_roster!(member) }

        it "deletes the cohort without mail unless asked to" do
          expect do
            delete(cohort_path(cohort), as: :turbo_stream)
          end.not_to have_enqueued_mail

          expect(Cohort.exists?(cohort.id)).to be(false)
          expect(CohortMembership.where(user: member)).to be_empty
        end

        it "tells each member by mail when asked to" do
          expect do
            delete(cohort_path(cohort), params: { notify: "1" }, as: :turbo_stream)
          end.to have_enqueued_mail(RosterNotificationMailer, :group_deleted_email)
            .with(a_hash_including(params: a_hash_including(group_title: cohort.title,
                                                            recipient: member)))

          expect(CGI.unescapeHTML(response.body))
            .to include(I18n.t("controllers.cohorts.destroyed_and_notified", count: 1))
        end
      end

      it "destroys the requested cohort" do
        expect do
          delete(cohort_path(cohort), as: :turbo_stream)
        end.to change(Cohort, :count).by(-1)
      end

      it "renders a successful response" do
        delete cohort_path(cohort), as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "does not destroy the cohort" do
        expect do
          delete(cohort_path(cohort), as: :turbo_stream)
        end.not_to change(Cohort, :count)
      end

      it "redirects to root (unauthorized)" do
        delete cohort_path(cohort), as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
