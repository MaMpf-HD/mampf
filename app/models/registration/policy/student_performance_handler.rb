module Registration
  class Policy
    # Handles the "Student Performance" policy
    # Checks if the user has passed a certification for a specific lecture.
    class StudentPerformanceHandler < Handler
      def evaluate(user)
        if lecture_ids.blank?
          return fail_result(
            :configuration_error,
            I18n.t("registration.policy.errors.missing_lecture"),
            classification: Registration::ScreeningService::CLASSIFICATION_BLOCKER,
            blocker_kind: Registration::ScreeningService::BLOCKER_KIND_CONFIGURATION
          )
        end

        if lectures.size != lecture_ids.size
          return fail_result(
            :lecture_not_found,
            I18n.t("registration.policy.errors.lecture_not_found"),
            classification: Registration::ScreeningService::CLASSIFICATION_BLOCKER,
            blocker_kind: Registration::ScreeningService::BLOCKER_KIND_CONFIGURATION
          )
        end

        certifications = StudentPerformance::Certification.where(
          lecture: lectures, user: user
        )
        outstanding = lectures_without_pass(certifications)

        return pass_result(:certification_passed) if outstanding.empty?

        fail_for_certification_status(
          certification_status(certifications, outstanding), outstanding
        )
      end

      def validate
        if lecture_ids.blank?
          policy.errors.add(
            :lecture_ids,
            I18n.t("registration.policy.errors.missing_lecture")
          )
        elsif lectures.size != lecture_ids.size
          policy.errors.add(
            :lecture_ids,
            I18n.t("registration.policy.errors.lecture_not_found")
          )
        else
          ineligible = lectures.reject(&:uses_exam_eligibility?)
          if ineligible.any?
            policy.errors.add(
              :lecture_ids,
              I18n.t(
                "registration.policy.errors.lecture_exam_eligibility_disabled",
                titles: ineligible.map(&:title).join(", ")
              )
            )
          end
        end
      end

      def summary
        lectures.map(&:title).join(", ").presence
      end

      private

        def lecture_ids
          policy.lecture_ids
        end

        def lectures
          return @lectures if defined?(@lectures)

          lectures_by_id = Lecture.where(id: lecture_ids).index_by do |lecture|
            lecture.id.to_s
          end
          @lectures = lecture_ids.filter_map { |lecture_id| lectures_by_id[lecture_id] }
        end

        # Every configured lecture has to be passed, so what matters is which of
        # them are not — a pass elsewhere cannot make up for them.
        def lectures_without_pass(certifications)
          passed_ids = certifications.passed.pluck(:lecture_id).to_set

          lectures.reject { |lecture| passed_ids.include?(lecture.id) }
        end

        # A single definitive failure settles the case, because no later grading
        # can turn it into a pass; anything else is still open.
        def certification_status(certifications, outstanding)
          statuses = certifications.where(lecture: outstanding)
                                   .map { |certification| certification.status.to_sym }
          return :failed if statuses.include?(:failed)
          return :pending if statuses.include?(:pending)

          :missing
        end

        def fail_for_certification_status(status, outstanding)
          message = I18n.t("registration.policy.errors.certification_not_passed")
          details = { certification_status: status,
                      outstanding_lectures: outstanding.map(&:title) }

          if status == :failed
            fail_result(
              :certification_not_passed,
              message,
              details,
              classification: Registration::ScreeningService::CLASSIFICATION_AUTO_REJECT,
              reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY,
              reason_code: :certification_not_passed,
              reason_label: message
            )
          else
            fail_result(
              :certification_not_passed,
              message,
              details,
              classification: Registration::ScreeningService::CLASSIFICATION_BLOCKER
            )
          end
        end
    end
  end
end
