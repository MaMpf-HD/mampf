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

ActiveRecord::Schema.define(version: 20170604173743) do

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
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hyperlinks", force: :cascade do |t|
    t.string "link"
    t.string "linkable_type"
    t.integer "linkable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linkable_type", "linkable_id"], name: "index_hyperlinks_on_linkable_type_and_linkable_id"
  end

  create_table "learning_assets", force: :cascade do |t|
    t.string "title"
    t.string "author"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "learning_manuscripts", force: :cascade do |t|
    t.integer "learning_asset_id"
    t.integer "manuscript_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_asset_id"], name: "index_learning_manuscripts_on_learning_asset_id"
    t.index ["manuscript_id"], name: "index_learning_manuscripts_on_manuscript_id"
  end

  create_table "learning_references", force: :cascade do |t|
    t.integer "learning_asset_id"
    t.integer "external_reference_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_reference_id"], name: "index_learning_references_on_external_reference_id"
    t.index ["learning_asset_id"], name: "index_learning_references_on_learning_asset_id"
  end

  create_table "learning_video_files", force: :cascade do |t|
    t.integer "learning_asset_id"
    t.integer "video_file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_asset_id"], name: "index_learning_video_files_on_learning_asset_id"
    t.index ["video_file_id"], name: "index_learning_video_files_on_video_file_id"
  end

  create_table "learning_video_streams", force: :cascade do |t|
    t.integer "learning_asset_id"
    t.integer "video_stream_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_asset_id"], name: "index_learning_video_streams_on_learning_asset_id"
    t.index ["video_stream_id"], name: "index_learning_video_streams_on_video_stream_id"
  end

  create_table "lectures", force: :cascade do |t|
    t.string "term"
    t.string "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "teacher_id"
    t.index ["teacher_id"], name: "index_lectures_on_teacher_id"
  end

  create_table "manuscripts", force: :cascade do |t|
    t.integer "pages"
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

  create_table "video_files", force: :cascade do |t|
    t.integer "width"
    t.integer "height"
    t.integer "size"
    t.integer "length"
    t.string "codec"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "video_streams", force: :cascade do |t|
    t.integer "width"
    t.integer "height"
    t.integer "size"
    t.integer "length"
    t.string "authoring_software"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
