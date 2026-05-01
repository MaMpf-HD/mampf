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

        if certifications.passed.exists?
          pass_result(:certification_passed)
        else
          fail_for_certification_status(certification_status(certifications))
        end
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

        def certification_status(certifications)
          statuses = certifications.map { |certification| certification.status.to_sym }
          return :pending if statuses.include?(:pending)
          return :failed if statuses.include?(:failed)

          :missing
        end

        def fail_for_certification_status(status)
          message = I18n.t("registration.policy.errors.certification_not_passed")

          if status == :failed
            fail_result(
              :certification_not_passed,
              message,
              { certification_status: status },
              classification: Registration::ScreeningService::CLASSIFICATION_AUTO_REJECT,
              reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY,
              reason_code: :certification_not_passed,
              reason_label: message
            )
          else
            fail_result(
              :certification_not_passed,
              message,
              { certification_status: status },
              classification: Registration::ScreeningService::CLASSIFICATION_BLOCKER
            )
          end
        end
    end
  end
end
