# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2020_06_13_112557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "consumptions", force: :cascade do |t|
    t.integer "medium_id"
    t.text "sort"
    t.text "mode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "interactions", force: :cascade do |t|
    t.text "session_id"
    t.text "referrer_url"
    t.text "full_path"
    t.datetime "created_at", precision: nil
    t.string "study_participant"
  end

  create_table "probes", force: :cascade do |t|
    t.integer "question_id"
    t.integer "quiz_id"
    t.boolean "correct"
    t.text "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "progress"
    t.integer "success"
    t.string "study_participant"
    t.text "input"
    t.integer "remark_id"
  end
end
