module Registration
  # Identifies registerable items (Tutorials, Talks, or Cohorts)
  # from the parent lecture that are not yet part of the campaign.
  # Filters based on lecture type: seminars show Talks, regular lectures show Tutorials.
  # Cohorts are available for all lecture types.
  class AvailableItemsService
    def initialize(campaign)
      @campaign = campaign
      @lecture = campaign.campaignable
    end

    def items
      return {} unless @lecture.is_a?(Lecture)

      groups = {}
      add_tutorials(groups) unless @lecture.seminar?
      add_talks(groups) if @lecture.seminar?
      add_cohorts(groups)
      groups
    end

    def creatable_types
      return [] unless @lecture.is_a?(Lecture)

      types = []
      types << "Tutorial" unless @lecture.seminar?
      types << "Talk" if @lecture.seminar?
      types << "Enrollment Group"
      types << "Planning Survey"
      types << "Other Group"
      types
    end

    private

      def add_tutorials(groups)
        used_ids = Registration::Item.where(registerable_type: "Tutorial").pluck(:registerable_id)
        tutorials = @lecture.tutorials.where.not(id: used_ids)
        groups[:tutorials] = tutorials if tutorials.any?
      end

      def add_talks(groups)
        used_ids = Registration::Item.where(registerable_type: "Talk").pluck(:registerable_id)
        talks = @lecture.talks.where.not(id: used_ids)
        groups[:talks] = talks if talks.any?
      end

      def add_cohorts(groups)
        used_ids = Registration::Item.where(registerable_type: "Cohort").pluck(:registerable_id)
        cohorts = @lecture.cohorts.where.not(id: used_ids)
        groups[:cohorts] = cohorts if cohorts.any?
      end
  end
end
