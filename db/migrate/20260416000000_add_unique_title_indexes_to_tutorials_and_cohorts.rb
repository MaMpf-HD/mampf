class AddUniqueTitleIndexesToTutorialsAndCohorts < ActiveRecord::Migration[8.0]
  def up
    fill_missing_tutorial_titles
    deduplicate_tutorials
    deduplicate_cohorts

    add_index :tutorials, [:lecture_id, :title],
              unique: true,
              name: "index_tutorials_on_lecture_id_and_title_unique"
    add_index :cohorts, [:context_type, :context_id, :title],
              unique: true,
              name: "index_cohorts_on_context_and_title_unique"

    change_column_null :tutorials, :title, false
  end

  def down
    change_column_null :tutorials, :title, true
    remove_index :tutorials,
                 name: "index_tutorials_on_lecture_id_and_title_unique"
    remove_index :cohorts,
                 name: "index_cohorts_on_context_and_title_unique"
  end

  private

    def fill_missing_tutorial_titles
      Tutorial.where("title IS NULL OR btrim(title) = ''")
              .find_each do |tutorial|
        tutorial.update_column(:title, "Tutorial #{tutorial.id}") # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def deduplicate_tutorials
      Tutorial.group(:lecture_id, :title)
              .having("COUNT(*) > 1")
              .pluck(:lecture_id, :title)
              .each do |lecture_id, title|
        Tutorial.where(lecture_id: lecture_id, title: title)
                .order(:id).offset(1)
                .each { |t| t.update_column(:title, "#{title} (#{t.id})") } # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def deduplicate_cohorts
      Cohort.group(:context_type, :context_id, :title)
            .having("COUNT(*) > 1")
            .pluck(:context_type, :context_id, :title)
            .each do |context_type, context_id, title|
        Cohort.where(context_type: context_type, context_id: context_id,
                     title: title)
              .order(:id).offset(1)
              .each { |c| c.update_column(:title, "#{title} (#{c.id})") } # rubocop:disable Rails/SkipsModelValidations
      end
    end
end
