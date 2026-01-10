require "rails_helper"

RSpec.describe("Roster::Maintenance", type: :request) do
  let(:lecture) { create(:lecture, locale: I18n.default_locale) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  before do
    Flipper.enable(:roster_maintenance)
    create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
  end

  describe "GET /lectures/:id/roster" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_roster_path(lecture)
        expect(response).to have_http_status(:success)
      end

      it "assigns group_type from params" do
        get lecture_roster_path(lecture, group_type: "tutorials")
        expect(response.body).to include('turbo-frame id="roster_maintenance_tutorials"')
      end

      it "assigns active_tab from params" do
        get lecture_roster_path(lecture, tab: "enrollment")
        expect(response).to have_http_status(:success)
        expect(response.body).to include('turbo-frame id="roster_maintenance_all"')
      end

      it "handles array group_type params" do
        get lecture_roster_path(lecture, group_type: ["tutorials", "cohorts"])
        expect(response.body).to include('turbo-frame id="roster_maintenance_tutorials_cohorts"')
      end

      it "defaults group_type to :all" do
        get lecture_roster_path(lecture)
        expect(response.body).to include('turbo-frame id="roster_maintenance_all"')
      end

      context "with existing groups" do
        let!(:tutorial) { create(:tutorial, lecture: lecture) }

        it "renders successfully" do
          get lecture_roster_path(lecture)
          expect(response).to have_http_status(:success)
        end

        context "when filtering unassigned participants" do
          let(:assigned_user) { create(:user) }
          let(:unassigned_user) { create(:user) }

          before do
            create(:lecture_membership, lecture: lecture, user: assigned_user)
            create(:lecture_membership, lecture: lecture, user: unassigned_user)
            create(:tutorial_membership, tutorial: tutorial, user: assigned_user)
          end

          it "only returns unassigned participants" do
            get lecture_roster_path(lecture, tab: "participants", filter: "unassigned")
            expect(response).to have_http_status(:success)
            expect(response.body).to include(unassigned_user.email)
            expect(response.body).not_to include(assigned_user.email)
          end
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_roster_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /tutorials/:id/roster" do
    let(:tutorial) { create(:tutorial, lecture: lecture) }

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get tutorial_roster_path(tutorial)
        expect(response).to have_http_status(:success)
      end

      it "includes participants data for component" do
        get tutorial_roster_path(tutorial)
        expect(controller.instance_variable_get(:@participants)).not_to be_nil
        expect(controller.instance_variable_get(:@pagy)).not_to be_nil
        expect(response.body).to include('id="participants-tab"')
      end
    end
  end

  describe "PATCH /tutorials/:id/roster" do
    let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: false) }

    context "as an editor" do
      before { sign_in editor }

      it "updates the manual_roster_mode flag" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { manual_roster_mode: true } }
        expect(tutorial.reload.manual_roster_mode).to be(true)
      end

      it "redirects to the roster index" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { manual_roster_mode: true } }
        expect(response).to redirect_to(lecture_roster_path(lecture, group_type: :tutorials))
      end

      context "with turbo stream" do
        it "returns turbo stream response" do
          patch tutorial_roster_path(tutorial),
                params: { rosterable: { manual_roster_mode: true } },
                as: :turbo_stream
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body)
            .to include('turbo-stream action="update" target="roster_maintenance_tutorials"')
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { manual_roster_mode: true } }
        expect(response).to redirect_to(root_path)
      end

      it "does not update the manual_roster_mode flag" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { manual_roster_mode: true } }
        expect(tutorial.reload.manual_roster_mode).to be(false)
      end
    end
  end

  describe "POST /tutorials/:id/roster/add_member" do
    let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
    let(:new_student) { create(:confirmed_user) }

    context "as an editor" do
      before { sign_in editor }

      it "adds the user to the roster" do
        expect do
          post(add_member_tutorial_path(tutorial), params: { email: new_student.email })
        end.to change { tutorial.members.count }.by(1)
      end

      it "propagates tutorial roster additions to the lecture roster" do
        expect do
          post(add_member_tutorial_path(tutorial), params: { email: new_student.email })
        end.to change { lecture.members.count }.by(1)
      end

      it "handles invalid email" do
        post add_member_tutorial_path(tutorial), params: { email: "invalid" }
        expect(flash[:alert]).to be_present
      end

      context "when group is locked" do
        let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: false) }
        let!(:campaign) do
          create(:registration_campaign, :open,
                 campaignable: lecture,
                 registration_items: [build(:registration_item, registerable: tutorial)])
        end

        it "rejects the request" do
          post add_member_tutorial_path(tutorial), params: { email: new_student.email }
          expect(flash[:alert]).to include(I18n.t("roster.errors.item_locked"))
          expect(tutorial.members).not_to include(new_student)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post add_member_tutorial_path(tutorial), params: { email: new_student.email }
        expect(response).to redirect_to(root_path)
      end

      it "does not add the user" do
        expect do
          post(add_member_tutorial_path(tutorial), params: { email: new_student.email })
        end.not_to(change { tutorial.members.count })
      end
    end
  end

  describe "DELETE /tutorials/:id/roster/remove_member" do
    let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
    let(:member) { create(:confirmed_user) }

    before { create(:tutorial_membership, tutorial: tutorial, user: member) }

    context "as an editor" do
      before { sign_in editor }

      it "removes the user from the roster" do
        expect do
          delete(remove_member_tutorial_path(tutorial, user_id: member.id))
        end.to change { tutorial.members.count }.by(-1)
      end

      it "does not remove the user from the lecture roster" do
        create(:lecture_membership, lecture: lecture, user: member)

        expect do
          delete(remove_member_tutorial_path(tutorial, user_id: member.id))
        end.not_to(change { lecture.members.count })
      end

      context "when group is locked" do
        let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: false) }
        let!(:campaign) do
          create(:registration_campaign, :open,
                 campaignable: lecture,
                 registration_items: [build(:registration_item, registerable: tutorial)])
        end

        it "rejects the request" do
          delete remove_member_tutorial_path(tutorial, user_id: member.id)
          expect(flash[:alert]).to include(I18n.t("roster.errors.item_locked"))
          expect(tutorial.members).to include(member)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        delete remove_member_tutorial_path(tutorial, user_id: member.id)
        expect(response).to redirect_to(root_path)
      end

      it "does not remove the user" do
        expect do
          delete(remove_member_tutorial_path(tutorial, user_id: member.id))
        end.not_to(change { tutorial.members.count })
      end
    end
  end

  describe "PATCH /tutorials/:id/roster/move_member" do
    let(:source) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
    let(:target) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
    let(:member) { create(:confirmed_user) }

    before { create(:tutorial_membership, tutorial: source, user: member) }

    context "as an editor" do
      before { sign_in editor }

      it "moves the user to the target group" do
        expect do
          patch(move_member_tutorial_path(source, user_id: member.id),
                params: { target_id: target.id })
        end.to change { source.members.count }.by(-1)
                                              .and(change { target.members.count }.by(1))
      end

      it "keeps lecture roster membership when moving within tutorials" do
        create(:lecture_membership, lecture: lecture, user: member)

        expect do
          patch(move_member_tutorial_path(source, user_id: member.id),
                params: { target_id: target.id })
        end.not_to(change { lecture.members.count })
      end

      it "sets the correct flash message" do
        patch move_member_tutorial_path(source, user_id: member.id),
              params: { target_id: target.id }
        expect(flash[:notice]).to eq(I18n.t("roster.messages.user_moved", target: target.title))
      end

      context "when target is locked" do
        let(:target) { create(:tutorial, lecture: lecture, manual_roster_mode: false) }
        let!(:campaign) do
          create(:registration_campaign, :open,
                 campaignable: lecture,
                 registration_items: [build(:registration_item, registerable: target)])
        end

        it "rejects the request" do
          patch move_member_tutorial_path(source, user_id: member.id),
                params: { target_id: target.id }
          expect(flash[:alert]).to include(I18n.t("roster.errors.target_locked"))
          expect(source.members).to include(member)
          expect(target.members).not_to include(member)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch move_member_tutorial_path(source, user_id: member.id),
              params: { target_id: target.id }
        expect(response).to redirect_to(root_path)
      end

      it "does not move the user" do
        expect do
          patch(move_member_tutorial_path(source, user_id: member.id),
                params: { target_id: target.id })
        end.not_to(change { source.members.count })
        expect(target.members.count).to eq(0)
      end
    end
  end

  describe "POST /lectures/:id/roster/enroll" do
    let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
    let(:new_student) { create(:confirmed_user) }

    context "as an editor" do
      before { sign_in editor }

      it "adds the user to the specified group" do
        expect do
          post(lecture_roster_enroll_path(lecture),
               params: { email: new_student.email, rosterable_id: "Tutorial-#{tutorial.id}" })
        end.to change { tutorial.members.count }.by(1)
      end

      it "handles invalid group selection" do
        post lecture_roster_enroll_path(lecture),
             params: { email: new_student.email, rosterable_id: "Invalid-1" }
        expect(flash[:alert]).to be_present
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post lecture_roster_enroll_path(lecture),
             params: { email: new_student.email, rosterable_id: "Tutorial-#{tutorial.id}" }
        expect(response).to redirect_to(root_path)
      end

      it "does not add the user" do
        expect do
          post(lecture_roster_enroll_path(lecture),
               params: { email: new_student.email, rosterable_id: "Tutorial-#{tutorial.id}" })
        end.not_to(change { tutorial.members.count })
      end
    end
  end

  describe "POST /cohorts/:id/roster/add_member" do
    let(:cohort) { create(:cohort, context: lecture, manual_roster_mode: true) }
    let(:new_student) { create(:confirmed_user) }

    context "as an editor" do
      before { sign_in editor }

      it "adds the user to the roster" do
        expect do
          post(add_member_cohort_path(cohort), params: { email: new_student.email })
        end.to change { cohort.members.count }.by(1)
      end

      it "does not add the user to the lecture roster by default" do
        expect do
          post(add_member_cohort_path(cohort), params: { email: new_student.email })
        end.not_to(change { lecture.members.count })
      end

      context "when cohort propagates to lecture" do
        let(:cohort) do
          create(:cohort, context: lecture, manual_roster_mode: true, propagate_to_lecture: true)
        end

        it "adds the user to the lecture roster" do
          expect do
            post(add_member_cohort_path(cohort), params: { email: new_student.email })
          end.to change { lecture.members.count }.by(1)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post add_member_cohort_path(cohort), params: { email: new_student.email }
        expect(response).to redirect_to(root_path)
      end

      it "does not add the user" do
        expect do
          post(add_member_cohort_path(cohort), params: { email: new_student.email })
        end.not_to(change { cohort.members.count })
      end
    end
  end

  describe "DELETE /cohorts/:id/roster/remove_member" do
    let(:cohort) { create(:cohort, context: lecture, manual_roster_mode: true) }
    let(:member) { create(:confirmed_user) }

    before { create(:cohort_membership, cohort: cohort, user: member) }

    context "as an editor" do
      before { sign_in editor }

      it "removes the user from the roster" do
        expect do
          delete(remove_member_cohort_path(cohort, user_id: member.id))
        end.to change { cohort.members.count }.by(-1)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        delete remove_member_cohort_path(cohort, user_id: member.id)
        expect(response).to redirect_to(root_path)
      end

      it "does not remove the user" do
        expect do
          delete(remove_member_cohort_path(cohort, user_id: member.id))
        end.not_to(change { cohort.members.count })
      end
    end
  end

  describe "PATCH /cohorts/:id/roster/move_member" do
    let(:source) { create(:cohort, context: lecture, manual_roster_mode: true) }
    let(:target) { create(:cohort, context: lecture, manual_roster_mode: true) }
    let(:member) { create(:confirmed_user) }

    before { create(:cohort_membership, cohort: source, user: member) }

    context "as an editor" do
      before { sign_in editor }

      it "moves the user to the target group" do
        expect do
          patch(move_member_cohort_path(source, user_id: member.id),
                params: { target_id: target.id })
        end.to change { source.members.count }.by(-1)
                                              .and(change { target.members.count }.by(1))
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch move_member_cohort_path(source, user_id: member.id),
              params: { target_id: target.id }
        expect(response).to redirect_to(root_path)
      end

      it "does not move the user" do
        expect do
          patch(move_member_cohort_path(source, user_id: member.id),
                params: { target_id: target.id })
        end.not_to(change { source.members.count })
        expect(target.members.count).to eq(0)
      end
    end
  end

  describe "PATCH /tutorials/:id/roster/self_materialization" do
    let(:tutorial) { create(:tutorial, lecture: lecture, self_materialization_mode: :disabled) }

    context "as an editor" do
      before { sign_in editor }

      it "updates the self_materialization_mode" do
        patch tutorial_update_self_materialization_path(tutorial),
              params: { self_materialization_mode: "add_only" }
        expect(tutorial.reload.self_materialization_mode).to eq("add_only")
      end

      it "returns turbo stream response" do
        patch tutorial_update_self_materialization_path(tutorial),
              params: { self_materialization_mode: "add_only" },
              as: :turbo_stream

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('action="replace"')
        expect(response.body).to include("actions_tutorial_#{tutorial.id}")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch tutorial_update_self_materialization_path(tutorial),
              params: { self_materialization_mode: "add_only" }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
