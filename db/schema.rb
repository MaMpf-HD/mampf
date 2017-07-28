# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170728133022) do

  create_table "additional_contents", force: :cascade do |t|
    t.integer "lecture_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_additional_contents_on_lecture_id"
    t.index ["tag_id"], name: "index_additional_contents_on_tag_id"
  end

  create_table "asset_media", force: :cascade do |t|
    t.integer "learning_asset_id"
    t.integer "medium_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_asset_id"], name: "index_asset_media_on_learning_asset_id"
    t.index ["medium_id"], name: "index_asset_media_on_medium_id"
  end

  create_table "asset_tags", force: :cascade do |t|
    t.integer "learning_asset_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_asset_id"], name: "index_asset_tags_on_learning_asset_id"
    t.index ["tag_id"], name: "index_asset_tags_on_tag_id"
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
    t.integer "learning_asset_id"
    t.integer "linked_asset_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_asset_id", "linked_asset_id"], name: "index_connections_on_learning_asset_id_and_linked_asset_id", unique: true
    t.index ["learning_asset_id"], name: "index_connections_on_learning_asset_id"
    t.index ["linked_asset_id"], name: "index_connections_on_linked_asset_id"
  end

  create_table "course_contents", force: :cascade do |t|
    t.integer "course_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_contents_on_course_id"
    t.index ["tag_id"], name: "index_course_contents_on_tag_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "disabled_contents", force: :cascade do |t|
    t.integer "lecture_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_disabled_contents_on_lecture_id"
    t.index ["tag_id"], name: "index_disabled_contents_on_tag_id"
  end

  create_table "erdbeere_assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kaviar_assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "keks_assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "learning_assets", force: :cascade do |t|
    t.text "title"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teachable_type"
    t.integer "teachable_id"
    t.string "heading"
    t.index ["teachable_type", "teachable_id"], name: "index_learning_assets_on_teachable_type_and_teachable_id"
  end

  create_table "lectures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "teacher_id"
    t.integer "course_id"
    t.integer "term_id"
    t.index ["term_id"], name: "index_lectures_on_term_id"
  end

  create_table "lesson_contents", force: :cascade do |t|
    t.integer "lesson_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_lesson_contents_on_lesson_id"
    t.index ["tag_id"], name: "index_lesson_contents_on_tag_id"
  end

  create_table "lesson_headings", force: :cascade do |t|
    t.integer "lesson_id"
    t.integer "section_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_lesson_headings_on_lesson_id"
    t.index ["section_id"], name: "index_lesson_headings_on_section_id"
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
    t.string "type"
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

  create_table "reste_assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "section_contents", force: :cascade do |t|
    t.integer "section_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "index_section_contents_on_section_id"
    t.index ["tag_id"], name: "index_section_contents_on_tag_id"
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

  create_table "sesam_assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "summer_terms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "winter_terms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
