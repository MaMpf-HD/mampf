# Organizes available groups into categorized lists (e.g., Tutorials, Cohorts)
# with formatted titles and capacity status for student transfers.
# Serves as a shared concern for components that need to display valid assignment
#  destinations and check for overbooking.
module RosterTransferable
  extend ActiveSupport::Concern

  def transfer_targets
    @transfer_targets ||= available_groups.group_by(&:class).map do |klass, groups|
      {
        type: klass.name.underscore.pluralize.to_sym,
        title: klass.model_name.human(count: 2),
        items: groups.map do |group|
          {
            group: group,
            id: group.id,
            title: helpers.group_title_with_capacity(group),
            overbooked: overbooked?(group)
          }
        end
      }
    end
  end

  def overbooked?(group)
    group.full?
  end
end
