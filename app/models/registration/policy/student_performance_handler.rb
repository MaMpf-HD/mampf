module Registration
  class Policy
    # Handles the "Student Performance" policy
    # Checks if the user has passed a certification for a specific lecture.
    class StudentPerformanceHandler < Handler
      def evaluate(user)
        if lecture_ids.blank?
          return fail_result(:configuration_error,
                             "Lectures not configured")
        end

        if lectures.size != lecture_ids.size
          return fail_result(:lecture_not_found,
                             "Lecture not found")
        end

        certifications = StudentPerformance::Certification.where(
          lecture: lectures, user: user
        )

        if certifications.passed.exists?
          pass_result(:certification_passed)
        else
          fail_result(
            :certification_not_passed,
            "Lecture performance certification required",
            certification_status: certification_status(certifications)
          )
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
    end
  end
end
