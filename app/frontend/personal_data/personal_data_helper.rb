module PersonalDataHelper
  # Users with LOCKED_PERSONAL_DATA_FIELDS still empty go through the steps and
  # confirm; program and Uni ID alone stay editable without them.
  def personal_data_steps(open_fields)
    return [] unless open_fields.intersect?(User::LOCKED_PERSONAL_DATA_FIELDS)

    steps = []
    steps << :name if open_fields.intersect?([:first_name, :last_name])
    steps << :matriculation_number if open_fields.include?(:matriculation_number)
    steps << :program if study_programs.any?
    steps + [:uni_id, :check]
  end

  def study_programs
    @study_programs ||=
      Program.offered_to_students
             .includes(:translations, subject: :translations)
             .sort_by do |program|
               [Program.degrees.keys.index(program.degree), program.subject.math? ? 0 : 1,
                program.name_with_subject]
             end
  end
end
