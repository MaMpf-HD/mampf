# Organizes available groups into categorized lists (e.g., Tutorials, Cohorts)
# with formatted titles and capacity status for student transfers.
# Serves as a shared concern for components that need to display valid assignment
#  destinations and check for overbooking.
module RosterTransferable
  extend ActiveSupport::Concern

  def transfer_targets
    return @transfer_targets if @transfer_targets

    targets = available_groups.group_by(&:class).map do |klass, groups|
      {
        type: klass.name.underscore.pluralize.to_sym,
        title: I18n.t("registration.item.groups.#{klass.name.underscore.pluralize}"),
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

    @transfer_targets = targets.sort_by { |target| group_order(target[:type]) }
  end

  def overbooked?(group)
    group.full?
  end

  private

    def group_order(type)
      case type
      when :tutorials, :talks then 1
      when :cohorts then 2
      else 3
      end
    end
end
