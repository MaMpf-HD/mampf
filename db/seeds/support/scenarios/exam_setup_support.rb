module Scenarios
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
      Scenarios::QuietLoggingSupport.with_quiet_logging do
        lecture = exam_lecture!
      end

      Rails.logger.debug("=== Demo Exam Setup ===")
      Scenarios::QuietLoggingSupport.with_quiet_logging do
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
      abort("Lecture #{lecture.id} has no certifications. Run just seed first.")
      # rubocop:enable Rails/Exit
    end

    private

      def demo_exams(lecture)
        Exam.where(lecture_id: lecture.id, title: DEMO_EXAM_TITLES)
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
