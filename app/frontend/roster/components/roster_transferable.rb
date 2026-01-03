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
