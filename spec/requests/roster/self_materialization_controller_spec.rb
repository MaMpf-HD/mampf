require "rails_helper"

RSpec.describe("Roster::SelfMaterializationController", type: :request) do
  let(:lecture)  { create(:lecture, locale: I18n.default_locale) }
  let(:seminar)  { create(:lecture, :is_seminar, locale: I18n.default_locale) }
  let(:editor)   { create(:confirmed_user) }
  let(:student)  { create(:confirmed_user) }

  before do
    Flipper.enable(:roster_maintenance)
    create(:editable_user_join, user: editor, editable: lecture)
    create(:editable_user_join, user: editor, editable: seminar)
    editor.reload
    lecture.reload
  end

  describe("POST /roster/:id/self_add") do
    before { sign_in student }

    context "for a talk" do
      context "when not full" do
        let(:talk) do
          create(:talk,
                 lecture: seminar,
                 capacity: 1,
                 self_materialization_mode: "add_and_remove")
        end

        it "allows a user to self-add to a talk when it is not full" do
          post self_add_talk_path(talk),
               params: { type: "Talk", frame: "talk_user" }

          expect(talk.allocated_user_ids).to include(student.id)
        end

        it "sends an email when a user successfully self-adds to a talk" do
          expect do
            post(self_add_talk_path(talk),
                 params: { type: "Talk", frame: "talk_user" })
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      context "when full" do
        let(:talk) do
          create(:talk,
                 lecture: seminar,
                 capacity: 0,
                 self_materialization_mode: "add_and_remove")
        end

        it "shows an error when attempting to self-add to a full talk" do
          post self_add_talk_path(talk),
               params: { type: "Talk", frame: "talk_user" }

          expect(talk.allocated_user_ids).not_to include(student.id)
        end

        it "does not send an email when the self-add attempt fails" do
          expect do
            post(self_add_talk_path(talk),
                 params: { type: "Talk", frame: "talk_user" })
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end

      context "when self_materialization_mode is disabled" do
        let(:talk) do
          create(:talk,
                 lecture: seminar,
                 capacity: 10,
                 self_materialization_mode: "disabled")
        end

        it "shows an error when self-add is disabled" do
          post self_add_talk_path(talk),
               params: { type: "Talk", frame: "talk_user" }

          expect(talk.allocated_user_ids).not_to include(student.id)
        end
      end
    end

    context "for a tutorial" do
      context "when locked" do
        let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
        let!(:campaign) do
          create(:registration_campaign, :open,
                 campaignable: lecture,
                 registration_items: [
                   build(:registration_item, registerable: tutorial)
                 ])
        end

        it "shows an error when attempting to self-add to a locked tutorial" do
          post self_add_tutorial_path(tutorial),
               params: { type: "Tutorial", frame: "tutorial_user" }

          expect(tutorial.allocated_user_ids).not_to include(student.id)
        end
      end

      context "when not full" do
        let(:tutorial) do
          create(:tutorial,
                 lecture: lecture,
                 capacity: 1,
                 self_materialization_mode: "add_and_remove")
        end

        it "allows a user to self-add to a tutorial when it is not full" do
          post self_add_tutorial_path(tutorial),
               params: { type: "Tutorial", frame: "tutorial_user" }

          expect(tutorial.allocated_user_ids).to include(student.id)
        end
      end
    end

    context "for a cohort" do
      context "when not full" do
        let(:cohort) do
          create(:cohort,
                 context: lecture,
                 title: "test cohort",
                 capacity: 20,
                 self_materialization_mode: "add_and_remove")
        end

        it "allows a user to self-add to a cohort when it is not full" do
          post self_add_cohort_path(cohort),
               params: { type: "Cohort", frame: "cohort_user" }

          expect(cohort.allocated_user_ids).to include(student.id)
        end
      end
    end
  end

  describe("DELETE /roster/:id/self_remove") do
    context "for a talk" do
      context "when allowed" do
        let(:talk) do
          create(:talk,
                 lecture: seminar,
                 capacity: 1,
                 self_materialization_mode: "add_and_remove")
        end

        before do
          sign_in student
          post self_add_talk_path(talk),
               params: { type: "Talk", frame: "talk_user" }
          sign_in student
        end

        it "allows a user to self-remove from a talk" do
          talk.reload

          delete self_remove_talk_path(talk),
                 params: { type: "Talk", frame: "talk_user" }

          expect(talk.reload.allocated_user_ids).not_to include(student.id)
        end

        it "sends an email when a user self-removes from a talk" do
          expect do
            delete(self_remove_talk_path(talk),
                   params: { type: "Talk", frame: "talk_user" })
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      context "when self_materialization_mode is add_only" do
        let(:talk) do
          create(:talk,
                 lecture: seminar,
                 self_materialization_mode: "add_only")
        end

        before do
          sign_in student
          post self_add_talk_path(talk),
               params: { type: "Talk", frame: "talk_user" }
          sign_in student
        end

        it "shows an error when attempting to self-remove while removal is disabled" do
          delete self_remove_talk_path(talk),
                 params: { type: "Talk", frame: "talk_user" }

          expect(talk.reload.allocated_user_ids).to include(student.id)
        end
      end
    end

    context "for a tutorial" do
      context "when allowed" do
        let(:tutorial) do
          create(:tutorial,
                 lecture: lecture,
                 capacity: 1,
                 self_materialization_mode: "add_and_remove")
        end

        before do
          sign_in student
          post self_add_tutorial_path(tutorial),
               params: { type: "Tutorial", frame: "tutorial_user" }
          sign_in student
        end

        it "allows a user to self-remove from a tutorial" do
          delete self_remove_tutorial_path(tutorial),
                 params: { type: "Tutorial", frame: "tutorial_user" }

          expect(tutorial.reload.allocated_user_ids).not_to include(student.id)
        end
      end
    end

    context "for a cohort" do
      context "when allowed" do
        let(:cohort) do
          create(:cohort,
                 context: lecture,
                 title: "test cohort",
                 capacity: 20,
                 self_materialization_mode: "add_and_remove")
        end

        before do
          sign_in student
          post self_add_cohort_path(cohort),
               params: { type: "Cohort", frame: "cohort_user" }
          sign_in student
        end

        it "allows a user to self-remove from a cohort" do
          delete self_remove_cohort_path(cohort),
                 params: { type: "Cohort", frame: "cohort_user" }

          expect(cohort.reload.allocated_user_ids).not_to include(student.id)
        end
      end
    end
  end
end
