class RosterDetailComponent < ViewComponent::Base
  def initialize(rosterable:, group_type: nil)
    super()
    @rosterable = rosterable
    @lecture = rosterable.lecture
    @group_type = group_type
  end

  delegate :title, :locked?, to: :@rosterable

  def students
    User.where(id: @rosterable.roster_entries.pluck(@rosterable.roster_user_id_column))
        .order(:name)
  end

  def back_path
    helpers.lecture_roster_path(@lecture, group_type: group_type)
  end

  def group_type
    @group_type || @rosterable.roster_group_type
  end

  def add_member_path
    case @rosterable
    when Tutorial
      helpers.add_member_tutorial_path(@rosterable)
    when Talk
      helpers.add_member_talk_path(@rosterable)
    end
  end

  def remove_member_path(user)
    case @rosterable
    when Tutorial
      helpers.remove_member_tutorial_path(@rosterable, user)
    when Talk
      helpers.remove_member_talk_path(@rosterable, user)
    end
  end

  def move_member_path(user)
    case @rosterable
    when Tutorial
      helpers.move_member_tutorial_path(@rosterable, user)
    when Talk
      helpers.move_member_talk_path(@rosterable, user)
    end
  end

  def available_groups
    groups = case @rosterable
             when Tutorial then @lecture.tutorials
             when Talk then @lecture.talks
             else return []
    end
    groups.where.not(id: @rosterable.id).order(:title).reject(&:locked?)
  end

  private

    def group_type_for_rosterable
      case @rosterable
      when Tutorial then :tutorials
      when Talk then :talks
      else :all
      end
    end
end
