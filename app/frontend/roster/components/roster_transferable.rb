module RosterTransferable
  extend ActiveSupport::Concern

  def transfer_targets
    @transfer_targets ||= available_groups.map do |group|
      {
        group: group,
        id: group.id,
        title: helpers.group_title_with_capacity(group),
        overbooked: overbooked?(group)
      }
    end
  end

  def overbooked?(group)
    group.full?
  end
end
