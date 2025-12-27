module Roster
  class OverviewComponent < ViewComponent::Base
    def initialize(lecture:)
      super()
      @lecture = lecture
    end

    # Returns a list of groups to display.
    # Structure: { title: String, items: ActiveRecord::Relation, type: Symbol }
    def groups
      [
        tutorial_group
        # Future: seminar_group, exam_group
      ].compact
    end

    private

      def tutorial_group
        items = @lecture.tutorials.includes(:tutors).order(:title)
        return nil if items.empty?

        {
          title: Tutorial.model_name.human(count: 2),
          items: items,
          type: :tutorial
        }
      end

      # Helper to generate the correct polymorphic path
      def roster_path(item)
        case item
        when Tutorial
          helpers.tutorial_roster_path(item)
        else
          "#"
        end
      end
  end
end
