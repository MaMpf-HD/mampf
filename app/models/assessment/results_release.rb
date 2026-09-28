module Assessment
  # The gradebooks one release button covers: an exam's own, or every talk of
  # a seminar, which are published together once each speaker has a result.
  class ResultsRelease
    def initialize(exam: nil, seminar: nil)
      @exam = exam
      @seminar = seminar
    end

    def gradebooks
      @gradebooks ||= if @exam
        [@exam.assessment]
      else
        Assessment.where(assessable: @seminar.talks).includes(:assessable).to_a
      end
    end

    def published
      gradebooks.select(&:results_published?)
    end

    # Published results whose mail could not be queued are offered again, so
    # publishing once more sends it.
    def to_publish
      @to_publish ||= ready.select do |gradebook|
        !gradebook.results_published? || gradebook.results_notified_at.nil?
      end
    end

    def publish!
      to_publish.each(&:publish_results!)
    end

    def withdraw!
      published.each(&:withdraw_results!)
    end

    # A speaker of two talks is one person.
    def people_count
      user_ids(to_publish).size
    end

    # Whoever was told when these results first went out is not mailed again.
    def mail_count
      user_ids(to_publish.select { |gradebook| gradebook.results_notified_at.nil? }).size
    end

    private

      def ready
        return Assessment.complete_talk_gradebooks(@seminar) unless @exam

        gradebook = @exam.assessment
        gradebook.assessment_participations.with_result.exists? ? [gradebook] : []
      end

      def user_ids(gradebooks)
        Participation.with_result.where(assessment: gradebooks).distinct.pluck(:user_id)
      end
  end
end
