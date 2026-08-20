module Demo
  module ExamSetupSupport
    # One exam per campaign state, so the registration tab can be seen in all of
    # them: finalized with an editable roster, open for registration, closed and
    # awaiting review, and still a draft.
    DEMO_EXAM_ATTRIBUTES = [
      { title: "Demo Midterm", weeks: -2, location: "Lecture Hall A",
        capacity: 80, description: "Written midterm covering the first half." },
      { title: "Demo Practice Exam", weeks: 4, location: "Seminar Room B",
        capacity: 60, description: "Optional practice exam." },
      { title: "Demo Final Exam", weeks: 8, location: "Main Auditorium",
        capacity: 120, description: "Final exam, registration not open yet." },
      { title: "Demo Retake Exam", weeks: 12, location: "Lecture Hall A",
        capacity: 40, description: "Retake, registration closed and under review." }
    ].freeze

    DEMO_EXAM_TITLES = DEMO_EXAM_ATTRIBUTES.pluck(:title).freeze

    DEMO_MIDTERM_TITLE = "Demo Midterm".freeze
    DEMO_PRACTICE_TITLE = "Demo Practice Exam".freeze
    DEMO_RETAKE_TITLE = "Demo Retake Exam".freeze

    def setup_exams!

      lecture = nil
      Demo::QuietLoggingSupport.with_quiet_logging do
        lecture = exam_lecture!
      end

      Rails.logger.debug("=== Demo Exam Setup ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
        reset_demo_exams!(lecture)
        create_demo_exams!(lecture)
        attach_performance_policy!(lecture)
        open_demo_campaigns!(lecture)
        register_demo_students!(lecture)
        finalize_demo_midterm!(lecture)
        close_demo_retake!(lecture)
        print_exam_summary(lecture)
      end
      Rails.logger.debug("=== Demo Exam Setup Complete ===")
    end

    def exam_lecture!
      lecture = eligibility_lecture!
      return lecture if StudentPerformance::Certification.exists?(lecture_id: lecture.id)

      # rubocop:disable Rails/Exit
      abort("Lecture #{lecture.id} has no certifications. Run demo:eligibility first.")
      # rubocop:enable Rails/Exit
    end

    private

      def demo_exams(lecture)
        Exam.where(lecture_id: lecture.id, title: DEMO_EXAM_TITLES)
      end

      # A finalized campaign refuses to be destroyed and so does an exam with a
      # roster, both for good reasons. Demo data is not worth working around
      # them one call at a time, so it goes by the shortest route.
      def reset_demo_exams!(lecture)
        exams = demo_exams(lecture)
        return if exams.empty?

        campaign_ids = Registration::Item
                       .where(registerable_type: "Exam", registerable_id: exams.ids)
                       .pluck(:registration_campaign_id)

        # Roster entries carry the campaign that admitted them, so they go
        # before it does.
        ExamRosterEntry.where(exam_id: exams.ids).delete_all
        Registration::UserRegistration.where(registration_campaign_id: campaign_ids)
                                      .delete_all
        Registration::Policy.where(registration_campaign_id: campaign_ids).delete_all
        Registration::Item.where(registration_campaign_id: campaign_ids).delete_all
        Registration::Campaign.where(id: campaign_ids).delete_all
        reset_exam_assessments!(exams)
        exams.delete_all
      end

      # Everything hanging off the gradebook, innermost first: once `demo:grading`
      # has run, deleting the assessment alone hits the foreign keys — and by
      # then the campaigns above are already gone, so an abort here is a mess.
      def reset_exam_assessments!(exams)
        assessment_ids = Assessment::Assessment
                         .where(assessable_type: "Exam", assessable_id: exams.ids)
                         .ids
        participation_ids = Assessment::Participation
                            .where(assessment_id: assessment_ids).select(:id)

        Assessment::TaskPoint.where(assessment_participation_id: participation_ids)
                             .delete_all
        Assessment::Participation.where(assessment_id: assessment_ids).delete_all
        Assessment::Task.where(assessment_id: assessment_ids).delete_all
        Assessment::GradeScheme.where(assessment_id: assessment_ids).delete_all
        Assessment::Assessment.where(id: assessment_ids).delete_all
      end

      def create_demo_exams!(lecture)
        DEMO_EXAM_ATTRIBUTES.each do |attrs|
          Exam.create!(
            lecture: lecture,
            title: attrs[:title],
            date: attrs[:weeks].weeks.from_now,
            location: attrs[:location],
            capacity: attrs[:capacity],
            description: attrs[:description]
          )
        end
      end

      # The retake stops at `closed`, which is where the review workspace lives
      # and where a finalization policy is evaluated but not yet enforced.
      def attach_performance_policy!(lecture)
        campaign = demo_exams(lecture).find_by(title: DEMO_RETAKE_TITLE)
                                      &.registration_campaign
        return unless campaign&.draft?

        Registration::Policy.create!(
          registration_campaign: campaign,
          kind: :student_performance,
          phase: :finalization,
          active: true,
          config: { "lecture_ids" => [lecture.id.to_s] }
        )
      end

      # The midterm already took place, so the deadline derived from its date is
      # in the past and the campaign would refuse to open. Demo data therefore
      # sets a reachable one first.
      def open_demo_campaigns!(lecture)
        [DEMO_MIDTERM_TITLE, DEMO_PRACTICE_TITLE, DEMO_RETAKE_TITLE].each do |title|
          campaign = demo_exams(lecture).find_by(title: title)&.registration_campaign
          next unless campaign&.draft?

          campaign.update!(registration_deadline: 1.week.from_now) if
            campaign.registration_deadline < Time.current
          campaign.update!(status: :open)
        end
      end

      def register_demo_students!(lecture)
        user_ids = TutorialMembership.where(tutorial_id: lecture.tutorial_ids)
                                     .pluck(:user_id).uniq

        register_demo_users!(lecture, DEMO_MIDTERM_TITLE, user_ids, ratio: 0.9)
        register_demo_users!(lecture, DEMO_PRACTICE_TITLE, user_ids, ratio: 0.5)
        register_demo_users!(lecture, DEMO_RETAKE_TITLE,
                             retake_user_ids(lecture, user_ids), ratio: 0.5)
      end

      # Only half the course signs up, and by index it would be chance whether
      # anyone the policy objects to is among them. Pending certifications go
      # first, then failed ones: the former reach the workspace as blockers, the
      # latter as projected rejections.
      def retake_user_ids(lecture, user_ids)
        certifications = StudentPerformance::Certification
                         .where(lecture_id: lecture.id, user_id: user_ids)

        (certifications.pending.pluck(:user_id) +
         certifications.failed.pluck(:user_id) +
         user_ids).uniq
      end

      def register_demo_users!(lecture, title, user_ids, ratio:)
        exam = demo_exams(lecture).find_by(title: title)
        campaign = exam&.registration_campaign
        item = campaign&.registration_items&.find_by(registerable_type: "Exam")
        return unless item

        user_ids.each_with_index do |uid, index|
          next unless (index % 10) < (ratio * 10)

          FactoryBot.create(:registration_user_registration,
                            user_id: uid,
                            registration_campaign: campaign,
                            registration_item: item,
                            status: :confirmed)
        end
      end

      def finalize_demo_midterm!(lecture)
        campaign = demo_exams(lecture).find_by(title: DEMO_MIDTERM_TITLE)
                                      &.registration_campaign
        return unless campaign&.open?

        campaign.update!(status: :closed)
        campaign.finalize!
      end

      def close_demo_retake!(lecture)
        campaign = demo_exams(lecture).find_by(title: DEMO_RETAKE_TITLE)
                                      &.registration_campaign
        campaign.update!(status: :closed) if campaign&.open?
      end

      def print_exam_summary(lecture)
        demo_exams(lecture).order(:date).each do |exam|
          Rails.logger.debug do
            "  #{exam.title}: campaign=#{exam.registration_campaign&.status} " \
              "roster=#{exam.exam_roster_entries.count}"
          end
        end
      end
  end
end
