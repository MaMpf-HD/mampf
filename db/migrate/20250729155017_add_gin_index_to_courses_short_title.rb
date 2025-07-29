# filepath: /home/denis/mampf/db/migrate/YYYYMMDDHHMMSS_add_gin_index_to_courses_short_title.rb
class AddGinIndexToCoursesShortTitle < ActiveRecord::Migration[8.0]
  # Disable the transaction that wraps the migration.
  # This is necessary to use `algorithm: :concurrently`.
  disable_ddl_transaction!

  def change
    # This index is for the trigram similarity search on course short_titles.
    # It completes the indexing needed for the Lecture search scope.
    add_index :courses, :short_title,
              using: :gin,
              opclass: :gin_trgm_ops,
              algorithm: :concurrently,
              name: "index_courses_on_short_title_trgm"
  end
end
