class ReplaceSortValuesForMedia < ActiveRecord::Migration[7.2]
  # NOTE: Use this migration only if you also updated the code in medium.rb
  # to reflect the new values for sort and replaced all occurences of the old
  # (food) values in the codebase
  def up
    # Create a mapping of old to new values
    mappings = {
      "Kaviar" => "LessonMaterial",
      "Sesam" => "WorkedExample",
      "Kiwi" => "Repetition",
      "Nuesse" => "Exercise",
      "Script" => "Manuscript",
      "Reste" => "Miscellaneous"
    }

    # Loop through each mapping and update records
    mappings.each do |old_value, new_value|
      # Note that we want to skip model validations here
      # because with the renmaing of the values of sort in the codebase,
      # all the existing records suddenly become invalid.
      # rubocop:disable Rails/SkipsModelValidations
      Medium.where(sort: old_value).update_all(sort: new_value)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  # NOTE: Use this down migration only if you also updated the code in medium.rb
  # to reflect the old (fod) values for sort and replaced all occurences of the
  # new values in the codebase
  def down
    # Create reverse mapping for rollback
    reverse_mappings = {
      "LessonMaterial" => "Kaviar",
      "WorkedExample" => "Sesam",
      "Repetition" => "Kiwi",
      "Exercise" => "Nuesse",
      "Manuscript" => "Script",
      "Miscellaneous" => "Reste"
    }

    # Loop through each reverse mapping and revert records
    reverse_mappings.each do |new_value, old_value|
      # Note that we want to skip model validations here
      # because with the renaming of the values of sort in the codebase,
      # all the existing records suddenly become invalid.
      # rubocop:disable Rails/SkipsModelValidations
      Medium.where(sort: new_value).update_all(sort: old_value)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
