require "rails_helper"

RSpec.describe("Roster::Maintenance", type: :request) do
  let(:lecture) { create(:lecture, locale: I18n.default_locale) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user, locale: "en") }

  before do
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

      it "counts the lecture's students by study program, groups without enrollment too" do
        program = create(:program, subject: create(:subject, name: "Mathematics"),
                                   name: "B.Sc. 100%", degree: :bsc100)
        create(:cohort, context: lecture, propagate_to_lecture: false)
          .add_user_to_roster!(create(:confirmed_user, program: program))

        get lecture_roster_path(lecture)

        rows = Nokogiri::HTML(response.body).css("details tbody tr")
                       .map { |row| row.css("th, td").map { |cell| cell.text.squish } }
        expect(rows).to eq([["Mathematics: B.Sc. 100%", "1"]])
      end

      it "returns turbo stream updates for participants sections" do
        get lecture_roster_participants_path(lecture), as: :turbo_stream

        expect(response).to have_http_status(:success)
        expect(response.body).to include('target="roster_participants_top_nav"')
        expect(response.body).to include('target="roster_participants_header_controls"')
        expect(response.body).to include('target="roster_participants_results"')
      end

      context "with a running registration" do
        let(:campaign) do
          create(:registration_campaign, :closed, campaignable: lecture,
                                                  description: "Tutorials WS")
        end
        let(:item) { campaign.registration_items.first }
        let(:registered) do
          create(:confirmed_user, first_name: "Anna", last_name: "Becker")
        end

        before do
          create(:registration_user_registration, :confirmed,
                 user: registered, registration_campaign: campaign, registration_item: item)
        end

        it "lists the registration in the registered view" do
          get lecture_roster_participants_path(lecture, view: "registered")

          rows = Nokogiri::HTML(response.body).css("#roster_participants_results tbody tr")
                         .map { |row| row.css("td").first(5).map { |cell| cell.text.squish } }
          expect(rows).to eq([[registered.tutorial_name, registered.matriculation_number.to_s,
                               item.title, I18n.t("roster.registrations.states.confirmed"), ""]])
          expect(response.body).to include(I18n.t("roster.registrations.hint"))
        end

        it "counts the registered people in the program distribution" do
          get lecture_roster_participants_path(lecture, view: "registered")

          heading = Nokogiri::HTML(response.body).css("details thead th").map(&:text)
          expect(heading).to include(I18n.t("roster.views.registered"))
        end

        it "points a search without roster hits to the registered view" do
          get lecture_roster_participants_path(lecture, search: "Becker")

          expect(response.body).to include(
            CGI.escapeHTML(I18n.t("roster.search_hits",
                                  count: 1, place: I18n.t("roster.views.registered")))
          )
        end

        it "points a search without registered hits to the enrolled view" do
          create(:lecture_membership, lecture: lecture,
                                      user: create(:confirmed_user, last_name: "Lovelace"))

          get lecture_roster_participants_path(lecture, view: "registered", search: "Lovelace")

          expect(response.body).to include(
            CGI.escapeHTML(I18n.t("roster.search_hits",
                                  count: 1, place: I18n.t("roster.views.enrolled")))
          )
        end

        context "and a second running campaign" do
          let(:later) do
            create(:registration_campaign, :open, campaignable: lecture,
                                                  description: "Seminar talks")
          end
          let(:other) { create(:confirmed_user, first_name: "Jonas", last_name: "Krause") }

          before do
            create(:registration_user_registration, :confirmed,
                   user: other, registration_campaign: later,
                   registration_item: later.registration_items.first)
          end

          def names
            Nokogiri::HTML(response.body)
                    .css("#roster_participants_results tbody tr td:first-child")
                    .map { |cell| cell.text.squish }
          end

          it "shows the campaign with the earliest deadline and offers the other" do
            get lecture_roster_participants_path(lecture, view: "registered")

            expect(names).to eq([registered.tutorial_name])
            expect(response.body).to include("Seminar talks")
          end

          it "shows the chosen campaign" do
            get lecture_roster_participants_path(lecture, view: "registered", campaign: later.id)

            expect(names).to eq([other.tutorial_name])
          end

          it "counts everyone of the chosen campaign in the statistics, whatever the search" do
            create(:registration_user_registration, :confirmed,
                   user: create(:confirmed_user, last_name: "Lovelace"),
                   registration_campaign: later,
                   registration_item: later.registration_items.second)

            get lecture_roster_participants_path(lecture, view: "registered",
                                                          campaign: later.id, search: "Krause")

            expect(names).to eq([other.tutorial_name])
            totals = Nokogiri::HTML(response.body).css("details tfoot td").map(&:text)
            expect(totals.map(&:squish)).to eq(["2"])
          end

          it "falls back to the earliest campaign for one it does not run" do
            foreign = create(:registration_campaign, :open)

            ["not-a-uuid", foreign.id].each do |id|
              get lecture_roster_participants_path(lecture, view: "registered", campaign: id)

              expect(names).to eq([registered.tutorial_name])
            end
          end

          it "puts a hint with a link to the campaign's registrations on each card" do
            get lecture_roster_path(lecture)

            links = Nokogiri::HTML(response.body)
                            .css("a[href*='view=registered']").pluck("href")
            expect(links).to contain_exactly(include("campaign=#{campaign.id}"),
                                             include("campaign=#{later.id}"))
            text = Nokogiri::HTML(response.body).text.squish
            [:registrations_hint_html, :deadline_passed_hint_html].each do |key|
              first_sentence = I18n.t("registration.campaign.#{key}", link: "").split(". ").first
              expect(text).to include(first_sentence)
            end
          end

          it "points a search without hits to the campaign that has them" do
            get lecture_roster_participants_path(lecture, view: "registered", search: "Krause")

            expect(response.body).to include(
              CGI.escapeHTML(I18n.t("roster.search_hits", count: 1, place: "Seminar talks"))
            )
          end
        end
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
            get lecture_roster_path(lecture, tab: "participants",
                                             filter: "unassigned")
            expect(response).to have_http_status(:redirect)
            follow_redirect!
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

      it "redirects to lecture roster without panel source" do
        get tutorial_roster_path(tutorial)
        expect(response).to redirect_to(lecture_roster_path(lecture))
      end

      it "returns http success for panel source" do
        get tutorial_roster_path(tutorial, source: "panel"), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /tutorials/:id/roster/add_member" do
    let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
    let(:new_student) { create(:confirmed_user) }

    context "as an editor" do
      before { sign_in editor }

      it "adds the user to the roster" do
        expect do
          post(add_member_tutorial_path(tutorial), params: { email: new_student.email })
        end.to change { tutorial.members.count }.by(1)
      end

      it "sends an email when a user is successfully added to tutorial" do
        perform_enqueued_jobs do
          expect do
            post(add_member_tutorial_path(tutorial), params: { email: new_student.email })
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_added_to_group_email_subject",
                 rosterable_title: tutorial.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
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

      it "includes user name and group name in the success flash" do
        post add_member_tutorial_path(tutorial), params: { email: new_student.email }
        expect(flash[:notice]).to eq(
          I18n.t("roster.messages.user_added",
                 user: new_student.info, group: tutorial.title)
        )
      end

      context "when user is already in this tutorial" do
        before { create(:tutorial_membership, tutorial: tutorial, user: new_student) }

        it "includes user name and group name in the already-member flash" do
          post add_member_tutorial_path(tutorial), params: { email: new_student.email }
          expect(flash[:notice]).to eq(
            I18n.t("roster.messages.user_already_member",
                   user: new_student.info, group: tutorial.title)
          )
        end
      end

      context "when user is already in another tutorial of the same lecture" do
        let!(:other_tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }

        before { create(:tutorial_membership, tutorial: other_tutorial, user: new_student) }

        it "includes user name and conflicting group in the alert" do
          post add_member_tutorial_path(tutorial), params: { email: new_student.email }
          expect(flash[:alert]).to eq(
            I18n.t("roster.errors.user_already_in_bundle",
                   user: new_student.info, group: other_tutorial.title)
          )
        end
      end

      context "when group is locked" do
        let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
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

        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              post(add_member_tutorial_path(tutorial), params: { email: new_student.email })
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
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

      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            post(add_member_tutorial_path(tutorial), params: { email: new_student.email })
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end
  end

  describe "DELETE /tutorials/:id/roster/remove_member" do
    let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
    let(:member) { create(:confirmed_user) }

    before { create(:tutorial_membership, tutorial: tutorial, user: member) }

    context "as an editor" do
      before { sign_in editor }

      it "removes the user from the roster" do
        expect do
          delete(remove_member_tutorial_path(tutorial, user_id: member.id))
        end.to change { tutorial.members.count }.by(-1)
      end

      it "sends an email when a user is successfully removed from tutorial" do
        perform_enqueued_jobs do
          expect do
            delete(remove_member_tutorial_path(tutorial, user_id: member.id))
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_removed_from_group_email_subject",
                 rosterable_title: tutorial.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end

      it "does not remove the user from the lecture roster" do
        create(:lecture_membership, lecture: lecture, user: member)

        expect do
          delete(remove_member_tutorial_path(tutorial, user_id: member.id))
        end.not_to(change { lecture.members.count })
      end

      it "includes user name in the flash" do
        delete remove_member_tutorial_path(tutorial, user_id: member.id)
        expect(flash[:notice]).to eq(
          I18n.t("roster.messages.user_removed", user: member.info)
        )
      end

      context "when group is locked" do
        let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
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

        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              delete(remove_member_tutorial_path(tutorial, user_id: member.id))
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
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

      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            delete(remove_member_tutorial_path(tutorial, user_id: member.id))
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end
  end

  describe "PATCH /tutorials/:id/roster/move_member" do
    let(:source) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
    let(:target) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
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

      it "sends an email when a user is successfully moved" do
        perform_enqueued_jobs do
          expect do
            patch(move_member_tutorial_path(source, user_id: member.id),
                  params: { target_id: target.id })
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_moved_between_groups_email_subject",
                 rosterable_title: target.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
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
        expect(flash[:notice]).to eq(
          I18n.t("roster.messages.user_moved_between_tutorials",
                 user: member.info, target: target.title, source: source.title)
        )
      end

      it "notifies the tutors of both tutorials" do
        old_tutor = create(:tutor_tutorial_join, tutorial: source).tutor
        new_tutor = create(:tutor_tutorial_join, tutorial: target).tutor

        perform_enqueued_jobs do
          patch(move_member_tutorial_path(source, user_id: member.id),
                params: { target_id: target.id })
        end

        recipients = ActionMailer::Base.deliveries.flat_map(&:to)
        expect(recipients).to include(member.email, old_tutor.email, new_tutor.email)
      end

      context "when target is locked" do
        let(:target) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
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

        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              patch(move_member_tutorial_path(source, user_id: member.id),
                    params: { target_id: target.id })
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end

      context "when source is locked" do
        let(:source) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
        let!(:campaign) do
          create(:registration_campaign, :open,
                 campaignable: lecture,
                 registration_items: [build(:registration_item, registerable: source)])
        end

        it "rejects the request" do
          patch move_member_tutorial_path(source, user_id: member.id),
                params: { target_id: target.id }
          expect(source.members).to include(member)
          expect(target.members).not_to include(member)
        end

        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              patch(move_member_tutorial_path(source, user_id: member.id),
                    params: { target_id: target.id })
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
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

  describe "PATCH /cohorts/:id/roster/move_member" do
    let(:source) { create(:cohort, context: lecture, skip_campaigns: true) }
    let(:target) { create(:cohort, context: lecture, skip_campaigns: true) }
    let(:member) { create(:confirmed_user) }

    before { sign_in editor }

    context "when the user is already in the target" do
      before do
        create(:cohort_membership, cohort: source, user: member)
        create(:cohort_membership, cohort: target, user: member)
      end

      it "leaves both rosters untouched" do
        expect do
          patch(move_member_cohort_path(source, user_id: member.id),
                params: { target_id: target.id, target_type: "Cohort" })
        end.not_to(change { [source.members.count, target.members.count] })
      end

      it "says so instead of reporting success" do
        patch move_member_cohort_path(source, user_id: member.id),
              params: { target_id: target.id, target_type: "Cohort" }

        expect(flash[:notice]).to be_nil
        expect(flash[:alert]).to eq(
          I18n.t("roster.messages.user_not_moved",
                 user: member.info, target: target.title)
        )
      end

      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            patch(move_member_cohort_path(source, user_id: member.id),
                  params: { target_id: target.id, target_type: "Cohort" })
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end
  end

  describe "POST /lectures/:id/roster/members" do
    let(:new_student) { create(:confirmed_user) }

    context "as an editor" do
      before { sign_in editor }

      it "adds the user to the lecture roster" do
        expect do
          post(add_member_lecture_path(lecture), params: { email: new_student.email })
        end.to change { lecture.members.count }.by(1)
      end

      it "handles invalid email" do
        post add_member_lecture_path(lecture), params: { email: "invalid@nonexistent.test" }
        expect(flash[:alert]).to be_present
      end

      it "returns turbo stream response" do
        post add_member_lecture_path(lecture),
             params: { email: new_student.email },
             as: :turbo_stream
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post add_member_lecture_path(lecture), params: { email: new_student.email }
        expect(response).to redirect_to(root_path)
      end

      it "does not add the user" do
        expect do
          post(add_member_lecture_path(lecture), params: { email: new_student.email })
        end.not_to(change { lecture.members.count })
      end
    end
  end

  describe "DELETE /lectures/:id/roster/members/:user_id" do
    let(:member) { create(:confirmed_user) }

    before { create(:lecture_membership, lecture: lecture, user: member) }

    context "as an editor" do
      before { sign_in editor }

      it "removes the user from the lecture roster" do
        expect do
          delete(remove_member_lecture_path(lecture, user_id: member.id))
        end.to change { lecture.members.count }.by(-1)
      end

      it "sends an email when a user is successfully removed" do
        perform_enqueued_jobs do
          expect do
            delete(remove_member_lecture_path(lecture, user_id: member.id))
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_removed_from_lecture_email_subject",
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end

      it "returns turbo stream response" do
        delete remove_member_lecture_path(lecture, user_id: member.id), as: :turbo_stream
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "handles non-existent user" do
        delete remove_member_lecture_path(lecture, user_id: 99_999), as: :turbo_stream
        expect(flash[:alert]).to be_present
      end

      # Leaving the lecture would take the member off their talk, and a talk
      # graded for them keeps them; the refusal is the roster's, in words.
      it "keeps a member whose talk in the seminar has been graded, and says so" do
        seminar = create(:lecture, :is_seminar)
        create(:editable_user_join, user: editor, editable: seminar)
        create(:lecture_membership, lecture: seminar, user: member)
        talk = create(:talk, lecture: seminar)
        talk.speakers << member
        talk.assessment.assessment_participations.create!(user: member, status: :reviewed,
                                                          grade_numeric: 2.0)

        delete remove_member_lecture_path(seminar, user_id: member.id), as: :turbo_stream

        expect(response.body).to include(I18n.t("roster.errors.grading_data_present"))
        expect(seminar.reload.members).to include(member)
        expect(talk.reload.speakers).to include(member)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        delete remove_member_lecture_path(lecture, user_id: member.id)
        expect(response).to redirect_to(root_path)
      end

      it "does not remove the user" do
        expect do
          delete(remove_member_lecture_path(lecture, user_id: member.id))
        end.not_to(change { lecture.members.count })
      end
    end
  end

  describe "PATCH /lectures/:id/roster/members/:user_id/move" do
    let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
    let(:target_tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
    let(:member) { create(:confirmed_user) }

    before do
      create(:lecture_membership, lecture: lecture, user: member)
      create(:tutorial_membership, tutorial: tutorial, user: member)
    end

    context "as an editor" do
      before { sign_in editor }

      it "moves the user to the target tutorial" do
        expect do
          patch(move_member_lecture_path(lecture, user_id: member.id),
                params: { target_id: target_tutorial.id, target_type: "Tutorial" })
        end.to change { tutorial.members.count }.by(-1)
                                                .and(change { target_tutorial.members.count }.by(1))
      end

      it "sends an email when a user is successfully moved" do
        perform_enqueued_jobs do
          expect do
            patch(move_member_lecture_path(lecture, user_id: member.id),
                  params: { target_id: target_tutorial.id, target_type: "Tutorial" })
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_moved_between_groups_email_subject",
                 rosterable_title: target_tutorial.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end

      it "keeps lecture membership when moving between tutorials" do
        expect do
          patch(move_member_lecture_path(lecture, user_id: member.id),
                params: { target_id: target_tutorial.id, target_type: "Tutorial" })
        end.not_to(change { lecture.members.count })
      end

      it "returns turbo stream response" do
        patch move_member_lecture_path(lecture, user_id: member.id),
              params: { target_id: target_tutorial.id, target_type: "Tutorial" },
              as: :turbo_stream
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "shows error when target is locked" do
        allow_any_instance_of(Tutorial).to receive(:locked?).and_return(true)

        patch move_member_lecture_path(lecture, user_id: member.id),
              params: { target_id: target_tutorial.id, target_type: "Tutorial" },
              as: :turbo_stream
        expect(flash[:alert]).to be_present
      end

      it "shows error when target not found" do
        patch move_member_lecture_path(lecture, user_id: member.id),
              params: { target_id: 99_999, target_type: "Tutorial" },
              as: :turbo_stream
        expect(flash[:alert]).to be_present
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch move_member_lecture_path(lecture, user_id: member.id),
              params: { target_id: target_tutorial.id, target_type: "Tutorial" }
        expect(response).to redirect_to(root_path)
      end

      it "does not move the user" do
        expect do
          patch(move_member_lecture_path(lecture, user_id: member.id),
                params: { target_id: target_tutorial.id, target_type: "Tutorial" })
        end.not_to(change { tutorial.members.count })
      end
    end
  end

  describe "PATCH /lectures/:id/roster/bulk_self_materialization" do
    let!(:free_tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
    let!(:campaign_tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
    let!(:campaign) { create(:registration_campaign, campaignable: lecture, status: :draft) }

    before do
      create(:registration_item,
             registration_campaign: campaign,
             registerable: campaign_tutorial)
    end

    context "as an editor" do
      before { sign_in editor }

      it "enables self-materialization through validated model updates" do
        patch roster_bulk_update_self_materialization_lecture_path(
          lecture,
          mode: :add_only
        ), as: :turbo_stream

        expect(response).to have_http_status(:success)
        expect(free_tutorial.reload.self_materialization_mode).to eq("add_only")
        expect(free_tutorial.skip_campaigns).to be(true)
        expect(campaign_tutorial.reload.self_materialization_mode).to eq("disabled")
        expect(campaign_tutorial.skip_campaigns).to be(false)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch roster_bulk_update_self_materialization_lecture_path(
          lecture,
          mode: :add_only
        ), as: :turbo_stream

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /cohorts/:id/roster/add_member" do
    let(:cohort) { create(:cohort, context: lecture, skip_campaigns: true) }
    let(:new_student) { create(:confirmed_user) }

    context "as an editor" do
      before { sign_in editor }

      it "adds the user to the roster" do
        expect do
          post(add_member_cohort_path(cohort), params: { email: new_student.email })
        end.to change { cohort.members.count }.by(1)
      end

      it "sends an email when a user is successfully added to the cohort" do
        perform_enqueued_jobs do
          expect do
            post(add_member_cohort_path(cohort), params: { email: new_student.email })
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_added_to_group_email_subject",
                 rosterable_title: cohort.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end

      it "does not add the user to the lecture roster by default" do
        expect do
          post(add_member_cohort_path(cohort), params: { email: new_student.email })
        end.not_to(change { lecture.members.count })
      end

      context "when cohort propagates to lecture" do
        let(:cohort) do
          create(:cohort, context: lecture, skip_campaigns: true, propagate_to_lecture: true)
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
    let(:cohort) { create(:cohort, context: lecture, skip_campaigns: true) }
    let(:member) { create(:confirmed_user) }

    before { create(:cohort_membership, cohort: cohort, user: member) }

    context "as an editor" do
      before { sign_in editor }

      it "removes the user from the roster" do
        expect do
          delete(remove_member_cohort_path(cohort, user_id: member.id))
        end.to change { cohort.members.count }.by(-1)
      end

      it "sends an email when a user is successfully removed" do
        perform_enqueued_jobs do
          expect do
            delete(remove_member_cohort_path(cohort, user_id: member.id))
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_removed_from_group_email_subject",
                 rosterable_title: cohort.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
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
    let(:source) { create(:cohort, context: lecture, skip_campaigns: true) }
    let(:target) { create(:cohort, context: lecture, skip_campaigns: true) }
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

      it "sends an email when a user is successfully moved" do
        perform_enqueued_jobs do
          expect do
            patch(move_member_cohort_path(source, user_id: member.id),
                  params: { target_id: target.id })
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(student.locale) do
          I18n.t("roster.mailer.roster_moved_between_groups_email_subject",
                 rosterable_title: target.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
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
end
