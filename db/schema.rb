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

ActiveRecord::Schema.define(version: 20170609161344) do

  create_table "contents", force: :cascade do |t|
    t.integer "course_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_contents_on_course_id"
    t.index ["tag_id"], name: "index_contents_on_tag_id"
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

  create_table "external_references", force: :cascade do |t|
    t.text "description"
  end

  create_table "learning_assets", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "project"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "learning_media", force: :cascade do |t|
    t.integer "medium_id"
    t.integer "learning_asset_id"
    t.index ["learning_asset_id"], name: "index_learning_media_on_learning_asset_id"
    t.index ["medium_id"], name: "index_learning_media_on_medium_id"
  end

  create_table "lectures", force: :cascade do |t|
    t.string "term"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "teacher_id"
    t.integer "course_id"
  end

  create_table "manuscripts", force: :cascade do |t|
    t.integer "pages"
  end

  create_table "media", force: :cascade do |t|
    t.string "title"
    t.string "author"
    t.text "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "actable_type"
    t.integer "actable_id"
    t.index ["actable_type", "actable_id"], name: "index_media_on_actable_type_and_actable_id"
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

  create_table "video_files", force: :cascade do |t|
    t.integer "width"
    t.integer "height"
    t.integer "size", limit: 8
    t.integer "frames_per_second"
    t.string "codec"
    t.integer "length"
  end

  create_table "video_streams", force: :cascade do |t|
    t.integer "width"
    t.integer "height"
    t.integer "frames_per_second"
    t.string "authoring_software"
    t.integer "length"
  end

end
