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

ActiveRecord::Schema.define(version: 20170611164316) do

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

  create_table "lectures", force: :cascade do |t|
    t.string "term"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "teacher_id"
    t.integer "course_id"
  end

  create_table "lesson_contents", force: :cascade do |t|
    t.integer "lesson_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_lesson_contents_on_lesson_id"
    t.index ["tag_id"], name: "index_lesson_contents_on_tag_id"
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
    t.boolean "has_video_stream?"
    t.boolean "has_video_file?"
    t.boolean "has_video_thumbnail?"
    t.boolean "has_manuscript?"
    t.boolean "has_external_reference?"
    t.text "video_stream_link"
    t.text "video_file_link"
    t.text "video_thumbnail_link"
    t.text "manuscript_link"
    t.text "external_reference_link"
    t.integer "width"
    t.integer "height"
    t.integer "embedded_width"
    t.integer "embedded_height"
    t.integer "length"
    t.bigint "video_size"
    t.integer "pages"
    t.integer "manuscript_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "author"
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

end
