require "rails_helper"

RSpec.describe("Roster::SelfMaterializationController", type: :request) do
  let(:user) { create(:confirmed_user_en) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:tutorial) do
    create(:tutorial,
           lecture: lecture,
           skip_campaigns: true,
           self_materialization_mode: :add_and_remove)
  end
  let(:camp_tutorial) do
    create(:tutorial,
           lecture: lecture,
           skip_campaigns: false)
  end
  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:item) do
    create(:registration_item,
           registration_campaign: campaign,
           registerable: camp_tutorial)
  end

  before do
    create(:lecture_bookmark, user: user, lecture: lecture)
    sign_in user
  end

  describe "PATCH /tutorials/:id/roster/self_switch" do
    let(:other) do
      create(:tutorial, lecture: lecture, skip_campaigns: true,
                        self_materialization_mode: :add_and_remove)
    end

    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    it "moves the user from their tutorial to this one" do
      patch self_switch_tutorial_path(other), as: :turbo_stream

      expect(other.reload.members).to include(user)
      expect(tutorial.reload.members).not_to include(user)
      expect(response.body).to include(I18n.t("roster.messages.user_switched", group: other.title))
    end

    it "sends a user who declined to give their data to the form instead" do
      user.update!(personal_data_confirmed_at: nil, personal_data_declined_at: Time.current)

      patch self_switch_tutorial_path(other), as: :turbo_stream

      expect(response).to redirect_to(edit_personal_data_path)
      expect(tutorial.reload.members).to include(user)
      expect(other.reload.members).not_to include(user)
    end

    it "keeps the user in their tutorial when this one is full" do
      other.update!(capacity: 1)
      create(:tutorial_membership, tutorial: other, user: create(:confirmed_user))

      patch self_switch_tutorial_path(other), as: :turbo_stream

      expect(tutorial.reload.members).to include(user)
      expect(other.reload.members).not_to include(user)
    end
  end

  describe "POST /tutorials/:id/roster/self_add" do
    it "adds the user to the tutorial" do
      expect do
        post(self_add_tutorial_path(tutorial), as: :turbo_stream)
      end.to change { tutorial.members.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("roster.messages.user_added",
               user: user.info,
               group: tutorial.title)
      )
    end

    it "sends a user who declined to give their data to the form instead" do
      user.update!(personal_data_confirmed_at: nil, personal_data_declined_at: Time.current)

      expect do
        post(self_add_tutorial_path(tutorial), as: :turbo_stream)
      end.not_to(change { tutorial.members.count })

      expect(response).to redirect_to(edit_personal_data_path)
    end

    it "updates the participation section" do
      post self_add_tutorial_path(tutorial), as: :turbo_stream

      expect(response.body).to include('target="student_registration_participation"')
    end

    it "updates the self-enrollment row" do
      post self_add_tutorial_path(tutorial), as: :turbo_stream

      expect(response.body).to include('target="self_enrollment_body"')
    end

    context "when user is already in another tutorial of the same lecture" do
      let(:other_tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :add_and_remove)
      end

      before { create(:tutorial_membership, tutorial: other_tutorial, user: user) }

      it "returns a conflict error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.user_already_in_bundle",
                 user: user.info,
                 group: other_tutorial.title)
        )
      end

      it "does not add the user to the tutorial" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end
    end

    context "when the tutorial is locked" do
      it "returns a locked error flash" do
        post self_add_tutorial_path(camp_tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.item_locked"))
      end

      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            post(self_add_tutorial_path(camp_tutorial), as: :turbo_stream)
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end

      it "does not add the user" do
        expect do
          post(self_add_tutorial_path(camp_tutorial), as: :turbo_stream)
        end.not_to(change { camp_tutorial.members.count })
      end
    end

    context "when self-add is not allowed" do
      let(:tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :remove_only)
      end

      it "returns a not allowed error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.self_add_not_allowed", type: "Tutorial")
        )
      end

      it "does not add the user" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end
    end

    context "when the tutorial is full" do
      let(:tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :add_and_remove,
                          capacity: 1)
      end

      before do
        other_user = create(:confirmed_user)
        create(:tutorial_membership, tutorial: tutorial, user: other_user)
      end

      it "returns a capacity error flash" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.capacity_exceeded"))
      end

      it "does not add the user" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end

      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            post(self_add_tutorial_path(tutorial), as: :turbo_stream)
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end

    context "when user is already a member of this tutorial" do
      before { create(:tutorial_membership, tutorial: tutorial, user: user) }

      it "returns success without error" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
      end

      it "does not duplicate the membership" do
        expect do
          post(self_add_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end
    end

    context "uses user locale (not lecture locale) for response" do
      before { user.update!(locale: :en) }

      it "renders response in user locale" do
        post self_add_tutorial_path(tutorial), as: :turbo_stream

        expect(response.body).to include(
          I18n.t("registration.user_registration.participation.title", locale: :en)
        )
      end
    end

    context "when self-add succeeds and should send email" do
      it "sends an email" do
        perform_enqueued_jobs do
          expect do
            post(self_add_tutorial_path(tutorial), as: :turbo_stream)
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(user.locale) do
          I18n.t("roster.mailer.roster_added_to_group_email_subject",
                 rosterable_title: tutorial.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end
    end
  end

  describe "DELETE /tutorials/:id/roster/self_remove" do
    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    context "when the group is the student's only one with enrollment" do
      before { lecture.add_user_to_roster!(user) }

      it "ends the enrollment as left on their own and keeps the bookmark" do
        delete self_remove_tutorial_path(tutorial), as: :turbo_stream

        expect(lecture.reload.members).not_to include(user)
        expect(lecture.excluded_lecture_memberships.find_by(user: user)).to be_left_by_self
        expect(user.reload.lectures).to include(lecture)
        expect(CGI.unescapeHTML(response.body)).to include(
          I18n.t("roster.messages.self_removed_left_lecture",
                 group: tutorial.title, lecture: lecture.title_term_info_no_type),
          I18n.t("roster.messages.self_removed_bookmark_hint")
        )
      end

      # A registration keeps the card among the student's own lectures, where
      # it has no ✕.
      it "leaves out the dashboard hint while a registration remains" do
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        create(:registration_user_registration, :confirmed, user: user,
                                                            registration_campaign: campaign)

        delete self_remove_tutorial_path(tutorial), as: :turbo_stream

        expect(CGI.unescapeHTML(response.body))
          .not_to include(I18n.t("roster.messages.self_removed_bookmark_hint"))
      end

      it "mails that the bookmark stays" do
        perform_enqueued_jobs do
          delete self_remove_tutorial_path(tutorial), as: :turbo_stream
        end

        expected = I18n.with_locale(user.locale) do
          I18n.t("roster.mailer.roster_left_last_place", rosterable_title: tutorial.title)
        end
        expect(ActionMailer::Base.deliveries.last.text_part.body.decoded.squish)
          .to include(expected.squish)
      end

      it "keeps the student while a result or a closed exam registration holds them" do
        allow_any_instance_of(Rosters::LectureLeave)
          .to receive(:last_place_blockers).and_return([:held])

        delete self_remove_tutorial_path(tutorial), as: :turbo_stream

        expect(CGI.unescapeHTML(response.body)).to include(
          I18n.t("roster.errors.self_remove_held", group: tutorial.title)
        )
        expect(tutorial.reload.members).to include(user)
      end
    end

    it "removes the user from the tutorial" do
      expect do
        delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
      end.to change { tutorial.members.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(CGI.unescapeHTML(response.body)).to include(
        I18n.t("roster.messages.self_removed", group: tutorial.title)
      )
    end

    it "says the enrollment stays while another group remains" do
      lecture.add_user_to_roster!(user)
      create(:cohort, :enrollment, context: lecture, skip_campaigns: true)
        .add_user_to_roster!(user)

      delete self_remove_tutorial_path(tutorial), as: :turbo_stream

      expect(tutorial.reload.members).not_to include(user)
      expect(CGI.unescapeHTML(response.body)).to include(
        I18n.t("roster.messages.self_removed_still_enrolled",
               group: tutorial.title, lecture: lecture.title_term_info_no_type)
      )
    end

    it "updates the participation section" do
      delete self_remove_tutorial_path(tutorial), as: :turbo_stream

      expect(response.body).to include('target="student_registration_participation"')
    end

    it "takes the self-enrollment row off once no group is left on offer" do
      tutorial.update!(self_materialization_mode: :remove_only)

      delete self_remove_tutorial_path(tutorial), as: :turbo_stream

      expect(response.body)
        .to include(%(action="remove" target="#{SelfEnrollmentComponent::BLOCK_ID}"))
    end

    context "when the tutorial is locked" do
      it "returns a locked error flash" do
        delete self_remove_tutorial_path(camp_tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("roster.errors.item_locked"))
      end

      it "does not remove the user" do
        expect do
          delete(self_remove_tutorial_path(camp_tutorial), as: :turbo_stream)
        end.not_to(change { camp_tutorial.members.count })
      end
    end

    context "when self-remove is not allowed" do
      let(:tutorial) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :add_only)
      end

      it "returns a not allowed error flash" do
        delete self_remove_tutorial_path(tutorial), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("roster.errors.self_remove_not_allowed", type: "Tutorial")
        )
      end

      it "does not remove the user" do
        expect do
          delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
        end.not_to(change { tutorial.members.count })
      end
      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end

    context "when the talk holds a grade for the user" do
      let(:seminar) { create(:lecture, :is_seminar, :released_for_all) }
      let(:talk) do
        create(:talk, lecture: seminar, title: "Groups", skip_campaigns: true,
                      self_materialization_mode: :add_and_remove)
      end

      before do
        create(:lecture_bookmark, user: user, lecture: seminar)
        talk.add_user_to_roster!(user)
        talk.ensure_assessment!(requires_points: false)
        Assessment::Participation.create!(assessment: talk.assessment, user: user)
                                 .update!(grade_numeric: 2.0, grader: create(:confirmed_user),
                                          graded_at: Time.current, status: :reviewed)
      end

      it "says the result keeps the user, not that a switch failed" do
        delete self_remove_talk_path(talk), as: :turbo_stream

        expect(CGI.unescapeHTML(response.body))
          .to include(I18n.t("roster.errors.self_remove_graded", group: "Groups"))
        expect(talk.reload.speakers).to include(user)
      end
    end

    context "when self-remove succeeds and should send email" do
      it "sends an email" do
        perform_enqueued_jobs do
          expect do
            delete(self_remove_tutorial_path(tutorial), as: :turbo_stream)
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(user.locale) do
          I18n.t("roster.mailer.roster_removed_from_group_email_subject",
                 rosterable_title: tutorial.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end
    end
  end
end
