require "rails_helper"

RSpec.describe(Assessment::AchievementValuesController, type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:tutor) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:group) { create(:tutorial, lecture: lecture) }
  let(:student) { create(:confirmed_user) }
  let(:achievement) { create(:achievement, :boolean, lecture: lecture) }
  let(:row) do
    create(:lecture_membership, lecture: lecture, user: student)
    create(:tutorial_membership, tutorial: group, user: student)
    participation = achievement.assessment.assessment_participations.find_by!(user: student)
    participation.update!(tutorial: group)
    participation
  end

  before { group.tutors << tutor }

  def enter(value, as: tutor, scope: "tutorial")
    sign_in(as)
    patch(achievement_value_participation_path(row, grading_scope_type: scope),
          params: { grade: value }, as: :turbo_stream)
  end

  describe "PATCH /participations/:id/achievement_value" do
    it "keeps what the group's tutor entered and answers with the row and the summary" do
      enter("pass")

      expect(response).to have_http_status(:ok)
      expect(row.reload.grade_text).to eq("pass")
      expect(row.grader).to eq(tutor)
      expect(row).to be_pending
      expect(response.body).to include("achievement-participation-row-#{row.id}")
      expect(response.body).to include("pointing-summary")
      expect(response.body).to include(I18n.t("assessment.achievements.marking.met"))
    end

    it "clears the value again on a blank, and the record with it" do
      row.update!(grade_text: "pass")
      enter("")

      expect(row.reload.grade_text).to be_nil
      expect(row.grader).to be_nil
      record = StudentPerformance::Record.find_by(lecture: lecture, user: student)
      expect(record.achievements_ungraded_ids).to include(achievement.id)
    end

    it "refuses a value the achievement cannot read" do
      enter("maybe")

      expect(row.reload.grade_text).to be_nil
      kind = I18n.t("assessment.achievements.value_types.boolean")
      expect(response.body).to include(
        I18n.t("assessment.achievements.marking.invalid_value", value: "maybe", kind: kind)
      )

      # BigDecimal reads "Infinity" as a number above every threshold.
      achievement.update!(value_type: :numeric, threshold: 10)
      enter("Infinity")
      expect(row.reload.grade_text).to be_nil
    end

    # A type change and a value entry both take the achievement's lock; the
    # value is read against the type as it stands once the lock is held.
    it "reads the type under the lock, not as the request found it" do
      achievement.update!(value_type: :numeric, threshold: 10)
      allow_any_instance_of(Assessment::Participation).to receive(:with_lock)
        .and_wrap_original do |lock, *args, &block|
          achievement.update!(value_type: :boolean, threshold: nil)
          lock.call(*args, &block)
        end

      enter("12")

      expect(row.reload.grade_text).to be_nil
      expect(response.body).to include("12")
    end

    it "takes a number on a numeric achievement, and refuses one above a percentage" do
      achievement.update!(value_type: :numeric, threshold: 10)
      enter("12,5")
      expect(row.reload.grade_text).to eq("12.5")
      expect(StudentPerformance::Record.find_by(lecture: lecture, user: student)
                                       .achievements_met_ids).to include(achievement.id)

      enter("")
      achievement.update!(value_type: :percentage, threshold: 50)
      enter("120")
      expect(row.reload.grade_text).to be_nil
    end

    it "leaves an excused row alone" do
      row.update!(status: :exempt)
      enter("fail")

      expect(row.reload.grade_text).to be_nil
      expect(response.body).to include(I18n.t("assessment.grading_exam.status_word.exempt"))
    end

    it "keeps another group's tutor out" do
      other = create(:confirmed_user)
      create(:tutorial, lecture: lecture).tutors << other
      enter("pass", as: other)

      expect(row.reload.grade_text).to be_nil
    end

    # A blank row follows the student to their new group at the moment of
    # writing, whether or not a table has been drawn since the move.
    it "hands a blank row to the student's new group before asking who may enter" do
      other_group = create(:tutorial, lecture: lecture)
      other_tutor = create(:confirmed_user)
      other_group.tutors << other_tutor
      row
      student.tutorial_memberships.find_by!(tutorial: group).update!(tutorial: other_group)

      enter("pass")
      expect(row.reload.grade_text).to be_nil
      expect(response).to redirect_to(root_path)

      enter("pass", as: other_tutor)
      expect(row.reload.grade_text).to eq("pass")
      expect(row.tutorial).to eq(other_group)

      # recorded work stays with the group that recorded it
      student.tutorial_memberships.find_by!(tutorial: other_group).update!(tutorial: group)
      enter("fail")
      expect(row.reload.grade_text).to eq("pass")
      expect(row.tutorial).to eq(other_group)
    end

    it "lets the lecturer enter from the lecture's table, and locks the delete button" do
      enter("pass", as: teacher, scope: "lecture")

      expect(row.reload.grade_text).to eq("pass")
      expect(response.body).to include(group.title)
      expect(response.body).to include("achievement-delete-button")
      expect(response.body).to include(I18n.t("assessment.achievement_not_destructible.has_values"))
    end

    it "answers a reload with the row and the summary" do
      row.update!(grade_text: "pass")
      sign_in tutor
      patch refresh_achievement_value_participation_path(row, grading_scope_type: "tutorial"),
            as: :turbo_stream

      expect(response.body).to include("achievement-participation-row-#{row.id}")
      expect(response.body).to include("pointing-summary")
    end
  end

  describe "exemption on an achievement" do
    it "lets the lecturer excuse somebody with a note, and take it back" do
      sign_in teacher
      patch mark_as_exempt_path(row, grading_scope_type: "lecture"),
            params: { note: "Certificate" }, as: :turbo_stream
      expect(row.reload).to be_exempt
      expect(row.note).to eq("Certificate")
      expect(StudentPerformance::Record.find_by(lecture: lecture, user: student)
                                       .achievements_met_ids).to include(achievement.id)
      expect(response.body).to include(I18n.t("assessment.achievements.marking.exempt"))

      patch remove_exempt_path(row, grading_scope_type: "lecture"), as: :turbo_stream
      expect(row.reload).to be_pending
    end

    # Rows written before this branch may say reviewed; a certificate after
    # a value throws nothing away on an achievement.
    it "excuses somebody whose row already carries a value, whatever it says" do
      row.update!(grade_text: "fail", status: :reviewed)
      sign_in teacher
      patch mark_as_exempt_path(row, grading_scope_type: "lecture"),
            params: { note: "Certificate" }, as: :turbo_stream

      expect(row.reload).to be_exempt
    end

    it "is not the tutor's to enter" do
      sign_in tutor
      patch mark_as_exempt_path(row, grading_scope_type: "tutorial"),
            params: { note: "x" }, as: :turbo_stream

      expect(row.reload).to be_pending
    end
  end
end
