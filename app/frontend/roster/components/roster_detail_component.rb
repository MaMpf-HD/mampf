class RosterDetailComponent < ViewComponent::Base
  def initialize(rosterable:)
    super()
    @rosterable = rosterable
    @lecture = rosterable.lecture
  end

  delegate :title, to: :@rosterable

  def students
    User.where(id: @rosterable.roster_entries.pluck(@rosterable.roster_user_id_column))
        .order(:name)
  end

  def back_path
    helpers.lecture_roster_path(@lecture, group_type: group_type_for_rosterable)
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
