module Registration
  class Policy
    # Handles the "Student Performance" policy
    # Checks if the user has passed a certification for a specific lecture.
    class StudentPerformanceHandler < Handler
      def evaluate(user)
        if lecture_id.blank?
          return fail_result(:configuration_error,
                             "Lecture not configured")
        end
        unless lecture
          return fail_result(:lecture_not_found,
                             "Lecture not found")
        end

        cert = StudentPerformance::Certification.find_by(
          lecture: lecture, user: user
        )

        if cert&.passed?
          pass_result(:certification_passed)
        else
          fail_result(
            :certification_not_passed,
            "Lecture performance certification required",
            certification_status: cert&.status&.to_sym || :missing
          )
        end
      end

      def validate
        if lecture_id.blank?
          policy.errors.add(
            :lecture_id,
            I18n.t("registration.policy.errors.missing_lecture")
          )
        elsif !Lecture.exists?(lecture_id)
          policy.errors.add(
            :lecture_id,
            I18n.t("registration.policy.errors.lecture_not_found")
          )
        end
      end

      def summary
        lecture&.title
      end

      private

        def lecture_id
          config["lecture_id"]
        end

        def lecture
          return @lecture if defined?(@lecture)

          @lecture = Lecture.find_by(id: lecture_id)
        end
    end
  end
end
