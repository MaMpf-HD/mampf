# Displays the student membership list for a specific group, providing controls
# to add, remove, or move participants. It dynamically aggregates compatible
# transfer targets across different group types to facilitate flexible student
# reassignment.
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
    @students ||=
      User.where(id: @rosterable.roster_entries.pluck(@rosterable.roster_user_id_column))
          .order(:name)
          .to_a
  end

  def back_path
    helpers.lecture_roster_path(@lecture, group_type: group_type)
  end

  def group_type
    @group_type || roster_group_type
  end

  def add_member_path
    route_helper("add_member",
                 group_type: group_type,
                 active_tab: "groups",
                 frame_id: helpers.roster_maintenance_frame_id(group_type))
  end

  def remove_member_path(user)
    route_helper("remove_member", user,
                 group_type: group_type,
                 active_tab: "groups",
                 frame_id: helpers.roster_maintenance_frame_id(group_type))
  end

  def move_member_path(user)
    route_helper("move_member", user,
                 group_type: group_type,
                 active_tab: "groups",
                 frame_id: helpers.roster_maintenance_frame_id(group_type))
  end

  def available_groups
    # Lectures don't transfer to other Lectures
    return [] if @rosterable.is_a?(Lecture)

    # Dynamically fetch the collection (e.g. @lecture.tutorials) based on the type
    # Memoize to avoid re-fetching for every student row in the view if accessed multiple times
    @available_groups ||= begin
      groups = @lecture.public_send(roster_group_type).to_a

      if @rosterable.is_a?(Cohort)
        groups.concat(@lecture.tutorials.to_a) if @lecture.respond_to?(:tutorials)
        groups.concat(@lecture.talks.to_a) if @lecture.respond_to?(:talks)
      elsif @lecture.respond_to?(:cohorts)
        groups.concat(@lecture.cohorts.to_a)
      end

      groups.uniq!
      groups.reject! { |g| g.id == @rosterable.id && g.instance_of?(@rosterable.class) }
      groups.reject!(&:locked?)
      groups.sort_by(&:title)
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
