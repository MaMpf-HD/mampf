module RosterTransferable
  extend ActiveSupport::Concern

  def transfer_targets
    @transfer_targets ||= available_groups.map do |group|
      {
        group: group,
        overbooked: overbooked?(group)
      }
    end
  end

  def overbooked?(group)
    group.full?
  end
end
