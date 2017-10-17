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

ActiveRecord::Schema.define(version: 20171016171419) do

  create_table "chapters", force: :cascade do |t|
    t.integer "lecture_id"
    t.integer "number"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_chapters_on_lecture_id"
  end

  create_table "connections", force: :cascade do |t|
    t.integer "lecture_id"
    t.integer "preceding_lecture_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id", "preceding_lecture_id"], name: "index_connections_on_lecture_id_and_preceding_lecture_id", unique: true
    t.index ["lecture_id"], name: "index_connections_on_lecture_id"
    t.index ["preceding_lecture_id"], name: "index_connections_on_preceding_lecture_id"
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
    t.string "short_title"
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

  create_table "lecture_user_joins", force: :cascade do |t|
    t.integer "lecture_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_lecture_user_joins_on_lecture_id"
    t.index ["user_id"], name: "index_lecture_user_joins_on_user_id"
  end

  create_table "lectures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "teacher_id"
    t.integer "course_id"
    t.integer "term_id"
    t.boolean "kaviar"
    t.boolean "sesam"
    t.boolean "keks"
    t.boolean "reste"
    t.boolean "erdbeere"
    t.text "twitter"
    t.boolean "kiwi"
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

  create_table "links", force: :cascade do |t|
    t.integer "medium_id"
    t.integer "linked_medium_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linked_medium_id"], name: "index_links_on_linked_medium_id"
    t.index ["medium_id", "linked_medium_id"], name: "index_links_on_medium_id_and_linked_medium_id", unique: true
    t.index ["medium_id"], name: "index_links_on_medium_id"
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
    t.string "teachable_type"
    t.integer "teachable_id"
    t.string "heading"
    t.text "question_list"
    t.string "video_player"
    t.index ["teachable_type", "teachable_id"], name: "index_media_on_teachable_type_and_teachable_id"
  end

  create_table "medium_tag_joins", force: :cascade do |t|
    t.integer "medium_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medium_id"], name: "index_medium_tag_joins_on_medium_id"
    t.index ["tag_id"], name: "index_medium_tag_joins_on_tag_id"
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
    t.text "homepage"
  end

  create_table "terms", force: :cascade do |t|
    t.integer "year"
    t.string "season"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin"
    t.integer "subscription_type"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
