# Renders a list of groups (tutorials, exams, etc.) for a lecture.
# Can be filtered by group_type (:tutorials, :exams, :all).
class LectureGroupsComponent < ViewComponent::Base
  def initialize(lecture:, group_type: :all)
    super()
    @lecture = lecture
    @group_type = group_type
  end

  # Returns a list of groups to display based on the selected type.
  # Structure: { title: String, items: ActiveRecord::Relation, type: Symbol }
  def groups
    case @group_type
    when :tutorials
      [tutorial_group]
    when :talks
      [talk_group]
    when :exams
      # [exam_group] # Future implementation
      []
    else
      # :all or default
      [
        tutorial_group,
        talk_group
        # Future: exam_group
      ]
    end.compact
  end

  private

    def tutorial_group
      items = @lecture.tutorials.includes(:tutors).order(:title)
      return nil if items.empty?

      {
        title: Tutorial.model_name.human(count: 2),
        items: items,
        type: :tutorials
      }
    end

    def talk_group
      items = @lecture.talks.includes(:speakers).order(:title)
      return nil if items.empty?

      {
        title: Talk.model_name.human(count: 2),
        items: items,
        type: :talks
      }
    end

    # Helper to generate the correct polymorphic path
    def group_path(item)
      case item
      when Tutorial
        helpers.tutorial_roster_path(item)
      when Talk
        helpers.talk_roster_path(item)
      else
        "#"
      end
    end
end
