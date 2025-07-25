class AddSearchIndexesToCourses < ActiveRecord::Migration[8.0]
  def change
    # This index is for the trigram similarity search (word_similarity: true)
    # It allows for fast searching based on text similarity.
    add_index :courses, :title, using: :gin, opclass: :gin_trgm_ops,
                                name: "index_courses_on_title_trigram"

    # This index is for the full-text search (tsearch)
    # It uses a tsvector expression to index the title in a way that's
    # optimized for finding whole words and prefixes.
    add_index :courses, "to_tsvector('simple', title)", using: :gin,
                                                        name: "index_courses_on_title_tsearch"
  end
end
