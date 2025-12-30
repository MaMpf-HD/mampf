module RosterHelper
  def group_title_with_capacity(group)
    "#{group.title} (#{group.roster_entries.count}/#{group.capacity || "∞"})"
  end
end
