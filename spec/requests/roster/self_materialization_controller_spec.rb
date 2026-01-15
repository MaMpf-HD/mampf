require "rails_helper"

RSpec.describe("Roster::SelfMaterializationController", type: :request) do
  let(:lecture) { create(:lecture, locale: I18n.default_locale) }
  let(:seminar) { create(:lecture, :is_seminar, locale: I18n.default_locale) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  before do
    Flipper.enable(:roster_maintenance)
    create(:editable_user_join, user: editor, editable: lecture)
    create(:editable_user_join, user: editor, editable: seminar)
    editor.reload
    lecture.reload
  end

  describe("POST /roster/id/self_add") do
    before do
      sign_in student
    end
    context "for a talk" do
      context "when not full" do
        let(:talk) do
          create(:talk, lecture: seminar, capacity: 1, self_materialization_mode: "add_and_remove")
        end

        it("allows a user to self-add to a talk if not full") do
          post self_add_talk_path(talk,
                                  params: { type: "Talk",
                                            partial: "talks/talker",
                                            variable: "talk" })
          expect(talk.allocated_user_ids).to include(student.id)
        end
      end
      context "when full" do
        let(:talk) do
          create(:talk, lecture: seminar, capacity: 0, self_materialization_mode: "add_and_remove")
        end

        it("shows an error if trying to self-add to a full talk") do
          post self_add_talk_path(talk,
                                  params: { type: "Talk",
                                            partial: "talks/talker",
                                            variable: "talk" })
          expect(talk.allocated_user_ids).to_not(include(student.id))
        end
      end

      context "when self_materialization_mode is disabled" do
        let(:talk) do
          create(:talk, lecture: seminar, capacity: 10, self_materialization_mode: "disabled")
        end

        it("shows an error if trying to self-add when self_materialization_mode is disabled") do
          post self_add_talk_path(talk,
                                  params: { type: "Talk",
                                            partial: "talks/talker",
                                            variable: "talk" })
          expect(talk.allocated_user_ids).to_not(include(student.id))
        end
      end
    end

    context "for a tutorial" do
      context "when locked" do
        let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: false) }
        let!(:campaign) do
          create(:registration_campaign, :open,
                 campaignable: lecture,
                 registration_items: [build(:registration_item, registerable: tutorial)])
        end

        it("shows an error if trying to self-add to a locked tutorial") do
          post self_add_tutorial_path(tutorial,
                                      params: { type: "Tutorial",
                                                partial: "tutorials/tutorial_user",
                                                variable: "tutorial" })
          expect(tutorial.allocated_user_ids).to_not(include(student.id))
        end
      end

      context "when not full" do
        let(:tutorial) do
          create(:tutorial, lecture: lecture, capacity: 1,
                            self_materialization_mode: "add_and_remove")
        end

        it("allows a user to self-add to a tutorial if not full") do
          post self_add_tutorial_path(tutorial,
                                      params: { type: "Tutorial",
                                                partial: "tutorials/tutorial_user",
                                                variable: "tutorial" })
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

        it("allows a user to self-add to a cohort if not full") do
          post self_add_cohort_path(cohort,
                                    params: { type: "Cohort",
                                              partial: "cohorts/cohort_user",
                                              variable: "cohort" })
          expect(cohort.allocated_user_ids).to include(student.id)
        end
      end
    end
  end

  describe("DELETE /roster/id/self_remove") do
    context "for a talk" do
      context "when allowed" do
        let(:talk) do
          create(:talk, lecture: seminar, capacity: 1,
                        self_materialization_mode: "add_and_remove")
        end

        before do
          sign_in student
          post self_add_talk_path(talk,
                                  params: { type: "Talk",
                                            partial: "talks/talker",
                                            variable: "talk" })
          sign_in student
        end

        it("allows a user to self-remove from a talk") do
          talk.reload
          delete self_remove_talk_path(talk,
                                       params: { type: "Talk",
                                                 partial: "talks/talker",
                                                 variable: "talk" })
          talk.reload
          expect(talk.allocated_user_ids).to_not(include(student.id))
        end
      end

      context "when self_materialization_mode is add_only" do
        let(:talk) do
          create(:talk, lecture: seminar, self_materialization_mode: "add_only")
        end

        before do
          sign_in student
          post self_add_talk_path(talk,
                                  params: { type: "Talk",
                                            partial: "talks/talker",
                                            variable: "talk" })
          sign_in student
        end

        it("shows an error if trying to self-remove when not allowed") do
          talk.reload
          delete self_remove_talk_path(talk,
                                       type: "Talk",
                                       partial: "talks/talker",
                                       variable: "talk")
          talk.reload
          expect(talk.allocated_user_ids).to(include(student.id))
        end
      end
    end

    context "for a tutorial" do
      context "when allowed" do
        let(:tutorial) do
          create(:tutorial, lecture: lecture, capacity: 1,
                            self_materialization_mode: "add_and_remove")
        end

        before do
          sign_in student
          post self_add_tutorial_path(tutorial,
                                      params: { type: "Tutorial",
                                                partial: "tutorials/tutorial_user",
                                                variable: "tutorial" })
          sign_in student
        end

        it("allows a user to self-add to a tutorial when allowed") do
          tutorial.reload
          delete self_remove_tutorial_path(tutorial,
                                           type: "Tutorial",
                                           partial: "tutorials/tutorial_user",
                                           variable: "tutorial")
          tutorial.reload
          expect(tutorial.allocated_user_ids).to_not(include(student.id))
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
          post self_add_cohort_path(cohort,
                                    params: { type: "Cohort",
                                              partial: "cohorts/cohort_user",
                                              variable: "cohort" })
          sign_in student
        end

        it("allows a user to self-add to a cohort if not full") do
          delete self_remove_cohort_path(cohort,
                                         params: { type: "Cohort",
                                                   partial: "cohorts/cohort_user",
                                                   variable: "cohort" })
          cohort.reload
          expect(cohort.allocated_user_ids).to_not(include(student.id))
        end
      end
    end
  end
end
