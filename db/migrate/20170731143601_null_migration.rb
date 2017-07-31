class NullMigration < ActiveRecord::Migration[5.1]
  def up
    create_table "asset_medium_joins", force: :cascade do |t|
      t.integer "asset_id"
      t.integer "medium_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["asset_id"], name: "index_asset_medium_joins_on_asset_id"
      t.index ["medium_id"], name: "index_asset_medium_joins_on_medium_id"
    end

    create_table "asset_tag_joins", force: :cascade do |t|
      t.integer "asset_id"
      t.integer "tag_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["asset_id"], name: "index_asset_tag_joins_on_asset_id"
      t.index ["tag_id"], name: "index_asset_tag_joins_on_tag_id"
    end

    create_table "assets", force: :cascade do |t|
      t.text "title"
      t.string "sort"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "teachable_type"
      t.integer "teachable_id"
      t.string "heading"
      t.text "link"
      t.string "question_list"
      t.index ["teachable_type", "teachable_id"], name: "index_assets_on_teachable_type_and_teachable_id"
    end

    create_table "chapters", force: :cascade do |t|
      t.integer "lecture_id"
      t.integer "number"
      t.string "title"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["lecture_id"], name: "index_chapters_on_lecture_id"
    end

    create_table "connections", force: :cascade do |t|
      t.integer "asset_id"
      t.integer "linked_asset_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["asset_id", "linked_asset_id"], name: "index_connections_on_asset_id_and_linked_asset_id", unique: true
      t.index ["asset_id"], name: "index_connections_on_asset_id"
      t.index ["linked_asset_id"], name: "index_connections_on_linked_asset_id"
    end

    create_table "course_tag_joins", force: :cascade do |t|
      t.integer "course_id"
      t.integer "tag_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_course_tag_joins_on_course_id"
      t.index ["tag_id"], name: "index_course_tag_joins_on_tag_id"
    end

    create_table "courses", force: :cascade do |t|
      t.string "title"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "lecture_tag_additional_joins", force: :cascade do |t|
      t.integer "lecture_id"
      t.integer "tag_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["lecture_id"], name: "index_lecture_tag_additional_joins_on_lecture_id"
      t.index ["tag_id"], name: "index_lecture_tag_additional_joins_on_tag_id"
    end

    create_table "lecture_tag_disabled_joins", force: :cascade do |t|
      t.integer "lecture_id"
      t.integer "tag_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["lecture_id"], name: "index_lecture_tag_disabled_joins_on_lecture_id"
      t.index ["tag_id"], name: "index_lecture_tag_disabled_joins_on_tag_id"
    end

    create_table "lectures", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "teacher_id"
      t.integer "course_id"
      t.integer "term_id"
      t.index ["term_id"], name: "index_lectures_on_term_id"
    end

    create_table "lesson_section_joins", force: :cascade do |t|
      t.integer "lesson_id"
      t.integer "section_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["lesson_id"], name: "index_lesson_section_joins_on_lesson_id"
      t.index ["section_id"], name: "index_lesson_section_joins_on_section_id"
    end

    create_table "lesson_tag_joins", force: :cascade do |t|
      t.integer "lesson_id"
      t.integer "tag_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["lesson_id"], name: "index_lesson_tag_joins_on_lesson_id"
      t.index ["tag_id"], name: "index_lesson_tag_joins_on_tag_id"
    end

    create_table "lessons", force: :cascade do |t|
      t.integer "number"
      t.date "date"
      t.integer "lecture_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["lecture_id"], name: "index_lessons_on_lecture_id"
    end

    create_table "media", force: :cascade do |t|
      t.text "video_stream_link"
      t.text "video_file_link"
      t.text "video_thumbnail_link"
      t.text "manuscript_link"
      t.text "external_reference_link"
      t.integer "width"
      t.integer "height"
      t.integer "embedded_width"
      t.integer "embedded_height"
      t.string "length"
      t.integer "pages"
      t.string "manuscript_size"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "title"
      t.string "author"
      t.string "video_size"
      t.string "authoring_software"
      t.string "sort"
      t.integer "question_id"
      t.string "description"
    end

    create_table "relations", force: :cascade do |t|
      t.integer "tag_id"
      t.integer "related_tag_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["related_tag_id"], name: "index_relations_on_related_tag_id"
      t.index ["tag_id", "related_tag_id"], name: "index_relations_on_tag_id_and_related_tag_id", unique: true
      t.index ["tag_id"], name: "index_relations_on_tag_id"
    end

    create_table "section_tag_joins", force: :cascade do |t|
      t.integer "section_id"
      t.integer "tag_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["section_id"], name: "index_section_tag_joins_on_section_id"
      t.index ["tag_id"], name: "index_section_tag_joins_on_tag_id"
    end

    create_table "sections", force: :cascade do |t|
      t.integer "chapter_id"
      t.integer "number"
      t.string "title"
      t.string "number_alt"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["chapter_id"], name: "index_sections_on_chapter_id"
    end

    create_table "tags", force: :cascade do |t|
      t.string "title"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "teachers", force: :cascade do |t|
      t.string "name"
      t.string "email"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "terms", force: :cascade do |t|
      t.integer "year"
      t.string "season"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end

  def down
   raise ActiveRecord::IrreversibleMigration
  end
end
