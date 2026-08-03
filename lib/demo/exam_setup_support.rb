module Demo
  module ExamSetupSupport
    # One exam per campaign state, so the registration tab can be seen in all
    # three of them: finalized with an editable roster, open for registration,
    # and still a draft.
    DEMO_EXAM_ATTRIBUTES = [
      { title: "Demo Midterm", weeks: -2, location: "Lecture Hall A",
        capacity: 80, description: "Written midterm covering the first half." },
      { title: "Demo Practice Exam", weeks: 4, location: "Seminar Room B",
        capacity: 60, description: "Optional practice exam." },
      { title: "Demo Final Exam", weeks: 8, location: "Main Auditorium",
        capacity: 120, description: "Final exam, registration not open yet." }
    ].freeze

    DEMO_EXAM_TITLES = DEMO_EXAM_ATTRIBUTES.pluck(:title).freeze

    DEMO_MIDTERM_TITLE = "Demo Midterm".freeze
    DEMO_PRACTICE_TITLE = "Demo Practice Exam".freeze

    def setup_exams!
      setup_flags!

      lecture = nil
      Demo::QuietLoggingSupport.with_quiet_logging do
        lecture = exam_lecture!
      end

      Rails.logger.debug("=== Demo Exam Setup ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
        reset_demo_exams!(lecture)
        create_demo_exams!(lecture)
        open_demo_campaigns!(lecture)
        register_demo_students!(lecture)
        finalize_demo_midterm!(lecture)
        print_exam_summary(lecture)
      end
      Rails.logger.debug("=== Demo Exam Setup Complete ===")
    end

    def exam_lecture!
      lecture = lecture!
      return lecture if TutorialMembership.exists?(tutorial_id: lecture.tutorial_ids)

      # rubocop:disable Rails/Exit
      abort("Lecture #{lecture.id} has no tutorial roster. Run demo:rosters first.")
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
        Registration::Item.where(registration_campaign_id: campaign_ids).delete_all
        Registration::Campaign.where(id: campaign_ids).delete_all
        Assessment::Assessment.where(assessable_type: "Exam",
                                     assessable_id: exams.ids).delete_all
        exams.delete_all
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

      # The midterm already took place, so the deadline derived from its date is
      # in the past and the campaign would refuse to open. Demo data therefore
      # sets a reachable one first.
      def open_demo_campaigns!(lecture)
        [DEMO_MIDTERM_TITLE, DEMO_PRACTICE_TITLE].each do |title|
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
