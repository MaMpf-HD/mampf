module PersonalDataHelper
  # Lists the steps through the fields still open, ending on a check of all of
  # them. The Uni ID alone needs no steps: it is the user's to change anyway.
  def personal_data_steps(open_fields)
    return [] unless open_fields.intersect?(User::LOCKED_PERSONAL_DATA_FIELDS)

    steps = []
    steps << :name if open_fields.intersect?([:first_name, :last_name])
    steps << :matriculation_number if open_fields.include?(:matriculation_number)
    steps + [:uni_id, :check]
  end
end
