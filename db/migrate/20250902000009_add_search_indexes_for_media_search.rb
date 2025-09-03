class AddSearchIndexesForMediaSearch < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Add individual GIN indexes for tsearch on each searchable column.
    # The query planner is smart enough to use these separate indexes.
    add_index :media, :description, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently,
                                    name: "index_media_on_description_trgm"
    add_index :media, :content, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently,
                                name: "index_media_on_content_trgm"
    add_index :media, :external_link_description,
              using: :gin,
              opclass: :gin_trgm_ops,
              algorithm: :concurrently,
              name: "index_media_on_external_link_description_trgm"
    add_index :media, :text, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently,
                             name: "index_media_on_text_trgm"

    add_index :answers, :text, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently,
                               name: "index_answers_on_text_trgm"
    add_index :answers,
              :explanation, using: :gin, opclass: :gin_trgm_ops,
                            algorithm: :concurrently, name: "index_answers_on_explanation_trgm"

    add_index :sections, :title, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently,
                                 name: "index_sections_on_title_trgm"
  end
end
