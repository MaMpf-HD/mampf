module RosterHelper
  def group_title_with_capacity(group)
    "#{group.title} (#{group.roster_entries.count}/#{group.capacity || "∞"})"
  end

  def roster_group_types(lecture)
    if lecture.seminar?
      [:talks, :cohorts]
    else
      [:tutorials, :cohorts]
    end
  end

  def roster_maintenance_frame_id(group_type)
    suffix = group_type.is_a?(Array) ? group_type.join("_") : group_type
    "roster_maintenance_#{suffix}"
  end
end
