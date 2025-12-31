class RosterDetailComponent < ViewComponent::Base
  include RosterTransferable

  def initialize(rosterable:, group_type: nil)
    super()
    @rosterable = rosterable
    @lecture = rosterable.lecture
    @group_type = group_type
  end

  delegate :title, :locked?, :roster_group_type, to: :@rosterable

  def students
    User.where(id: @rosterable.roster_entries.pluck(@rosterable.roster_user_id_column))
        .order(:name)
  end

  def back_path
    helpers.lecture_roster_path(@lecture, group_type: group_type)
  end

  def group_type
    @group_type || roster_group_type
  end

  def add_member_path
    route_helper("add_member")
  end

  def remove_member_path(user)
    route_helper("remove_member", user)
  end

  def move_member_path(user)
    route_helper("move_member", user)
  end

  def available_groups
    # Dynamically fetch the collection (e.g. @lecture.tutorials) based on the type
    # Memoize to avoid re-fetching for every student row in the view if accessed multiple times
    @available_groups ||= begin
      groups = @lecture.public_send(roster_group_type)
      groups.where.not(id: @rosterable.id).order(:title).reject(&:locked?)
    end
  end

  def overbooked?(group = @rosterable)
    super
  end

  private

    def route_helper(prefix, *)
      # Dynamically call the correct helper, e.g. add_member_tutorial_path(@rosterable)
      # This relies on the route helpers following the convention: {action}_{model}_path
      method_name = "#{prefix}_#{@rosterable.model_name.singular_route_key}_path"
      helpers.public_send(method_name, @rosterable, *)
    end
end
