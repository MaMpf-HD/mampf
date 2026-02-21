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

      add_exams(groups) if campaign_accepts_exams?

      if campaign_accepts_non_exams?
        add_tutorials(groups) unless @lecture.seminar?
        add_talks(groups) if @lecture.seminar?
        add_cohorts(groups)
      end

      groups
    end

    def suggest_roster_creation?
      campaign_accepts_non_exams?
    end

    private

      def campaign_accepts_exams?
        !@campaign.registration_items.where.not(registerable_type: "Exam").exists?
      end

      def campaign_accepts_non_exams?
        !@campaign.registration_items.exists?(registerable_type: "Exam")
      end

      def add_exams(groups)
        used_ids = Registration::Item.where(registerable_type: "Exam")
                                     .pluck(:registerable_id)
        exams = @lecture.exams.where(skip_campaigns: false).where.not(id: used_ids)
        groups[:exams] = exams if exams.any?
      end

      def add_tutorials(groups)
        used = campaign_item_ids_for("Tutorial")
        tutorials = @lecture.tutorials
                            .where(skip_campaigns: false)
                            .where.not(id: used)
        groups[:tutorials] = tutorials if tutorials.any?
      end

      def add_talks(groups)
        used = campaign_item_ids_for("Talk")
        talks = @lecture.talks
                        .where(skip_campaigns: false)
                        .where.not(id: used)
        groups[:talks] = talks if talks.any?
      end

      def add_cohorts(groups)
        used = campaign_item_ids_for("Cohort")
        cohorts = @lecture.cohorts
                          .where(skip_campaigns: false)
                          .where.not(id: used)
        groups[:cohorts] = cohorts if cohorts.any?
      end

      def campaign_item_ids_for(type)
        Registration::Item
          .where(registration_campaign: @lecture.registration_campaigns)
          .where(registerable_type: type)
          .select(:registerable_id)
      end
  end
end
