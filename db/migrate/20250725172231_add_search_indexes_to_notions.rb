class AddSearchIndexesToNotions < ActiveRecord::Migration[8.0]
  def change
    # Index for trigram similarity search on notion titles
    add_index :notions, :title, using: :gin, opclass: :gin_trgm_ops,
                                name: "index_notions_on_title_trigram"

    # Index for full-text search on notion titles
    add_index :notions, "to_tsvector('simple', title)", using: :gin,
                                                        name: "index_notions_on_title_tsearch"
  end
end
