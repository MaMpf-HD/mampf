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

ActiveRecord::Schema[8.0].define(version: 2025_07_23_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "annotations", force: :cascade do |t|
    t.bigint "medium_id", null: false
    t.bigint "user_id", null: false
    t.text "timestamp", null: false
    t.text "comment"
    t.string "color", null: false
    t.integer "category", null: false
    t.integer "subcategory"
    t.boolean "visible_for_teacher", default: false, null: false
    t.integer "public_comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medium_id"], name: "index_annotations_on_medium_id"
    t.index ["user_id"], name: "index_annotations_on_user_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "lecture_id"
    t.bigint "announcer_id"
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "on_main_page", default: false
    t.index ["announcer_id"], name: "index_announcements_on_announcer_id"
    t.index ["lecture_id"], name: "index_announcements_on_lecture_id"
  end

  create_table "answers", force: :cascade do |t|
    t.text "text"
    t.boolean "value"
    t.text "explanation"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "question_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "lecture_id", null: false
    t.bigint "medium_id"
    t.text "title"
    t.datetime "deadline", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "accepted_file_type", default: ".pdf"
    t.date "deletion_date", default: "2200-01-01", null: false
    t.index ["lecture_id"], name: "index_assignments_on_lecture_id"
    t.index ["medium_id"], name: "index_assignments_on_medium_id"
  end

  create_table "chapters", force: :cascade do |t|
    t.integer "lecture_id"
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "position"
    t.text "display_number"
    t.boolean "hidden"
    t.text "details"
    t.index ["lecture_id"], name: "index_chapters_on_lecture_id"
  end

  create_table "claims", force: :cascade do |t|
    t.bigint "redemption_id", null: false
    t.string "claimable_type", null: false
    t.bigint "claimable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claimable_type", "claimable_id"], name: "index_claims_on_claimable"
    t.index ["redemption_id"], name: "index_claims_on_redemption_id"
  end

  create_table "commontator_comments", force: :cascade do |t|
    t.bigint "thread_id", null: false
    t.string "creator_type", null: false
    t.bigint "creator_id", null: false
    t.string "editor_type"
    t.bigint "editor_id"
    t.text "body", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "cached_votes_up", default: 0
    t.integer "cached_votes_down", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.index ["cached_votes_down"], name: "index_commontator_comments_on_cached_votes_down"
    t.index ["cached_votes_up"], name: "index_commontator_comments_on_cached_votes_up"
    t.index ["creator_id", "creator_type", "thread_id"], name: "index_commontator_comments_on_c_id_and_c_type_and_t_id"
    t.index ["editor_type", "editor_id"], name: "index_commontator_comments_on_editor_type_and_editor_id"
    t.index ["parent_id"], name: "index_commontator_comments_on_parent_id"
    t.index ["thread_id", "created_at"], name: "index_commontator_comments_on_thread_id_and_created_at"
  end

  create_table "commontator_subscriptions", force: :cascade do |t|
    t.bigint "thread_id", null: false
    t.string "subscriber_type", null: false
    t.bigint "subscriber_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscriber_id", "subscriber_type", "thread_id"], name: "index_commontator_subscriptions_on_s_id_and_s_type_and_t_id", unique: true
    t.index ["thread_id"], name: "index_commontator_subscriptions_on_thread_id"
  end

  create_table "commontator_threads", force: :cascade do |t|
    t.string "commontable_type"
    t.bigint "commontable_id"
    t.string "closer_type"
    t.bigint "closer_id"
    t.datetime "closed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closer_type", "closer_id"], name: "index_commontator_threads_on_closer_type_and_closer_id"
    t.index ["commontable_type", "commontable_id"], name: "index_commontator_threads_on_c_id_and_c_type", unique: true
  end

  create_table "course_self_joins", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "preceding_course_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_id", "preceding_course_id"], name: "index_course_self_joins_on_course_id_and_preceding_course_id", unique: true
    t.index ["course_id"], name: "index_course_self_joins_on_course_id"
    t.index ["preceding_course_id"], name: "index_course_self_joins_on_preceding_course_id"
  end

  create_table "course_tag_joins", force: :cascade do |t|
    t.integer "course_id"
    t.integer "tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_id"], name: "index_course_tag_joins_on_course_id"
    t.index ["tag_id"], name: "index_course_tag_joins_on_tag_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "short_title"
    t.boolean "organizational"
    t.text "organizational_concept"
    t.text "locale"
    t.boolean "term_independent", default: false
    t.text "image_data"
  end

  create_table "division_course_joins", force: :cascade do |t|
    t.bigint "division_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_division_course_joins_on_course_id"
    t.index ["division_id"], name: "index_division_course_joins_on_division_id"
  end

  create_table "division_translations", force: :cascade do |t|
    t.bigint "division_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.index ["division_id"], name: "index_division_translations_on_division_id"
    t.index ["locale"], name: "index_division_translations_on_locale"
  end

  create_table "divisions", force: :cascade do |t|
    t.bigint "program_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_divisions_on_program_id"
  end

  create_table "editable_user_joins", force: :cascade do |t|
    t.integer "editable_id"
    t.string "editable_type"
    t.integer "user_id"
    t.index ["editable_id", "editable_type", "user_id"], name: "polymorphic_many_to_many_idx"
    t.index ["editable_id", "editable_type"], name: "polymorphic_editable_idx"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.text "title"
    t.text "feedback"
    t.boolean "can_contact", default: false, null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "imports", force: :cascade do |t|
    t.bigint "medium_id", null: false
    t.string "teachable_type", null: false
    t.bigint "teachable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medium_id"], name: "index_imports_on_medium_id"
    t.index ["teachable_type", "teachable_id"], name: "index_imports_on_teachable_type_and_teachable_id"
  end

  create_table "item_self_joins", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "related_item_id", null: false
    t.index ["item_id"], name: "index_item_self_joins_on_item_id"
    t.index ["related_item_id"], name: "index_item_self_joins_on_related_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.text "start_time"
    t.text "sort"
    t.integer "page"
    t.text "description"
    t.text "link"
    t.text "explanation"
    t.bigint "medium_id"
    t.bigint "section_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "ref_number"
    t.text "pdf_destination"
    t.integer "position"
    t.boolean "quarantine"
    t.boolean "hidden"
    t.index ["medium_id"], name: "index_items_on_medium_id"
    t.index ["section_id"], name: "index_items_on_section_id"
  end

  create_table "lecture_user_joins", force: :cascade do |t|
    t.bigint "lecture_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["lecture_id"], name: "index_lecture_user_joins_on_lecture_id"
    t.index ["user_id"], name: "index_lecture_user_joins_on_user_id"
  end

  create_table "lectures", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "course_id"
    t.integer "term_id"
    t.integer "teacher_id"
    t.integer "start_chapter"
    t.boolean "absolute_numbering"
    t.integer "start_section"
    t.text "organizational_concept"
    t.boolean "organizational"
    t.boolean "muesli"
    t.text "released"
    t.text "content_mode"
    t.text "passphrase"
    t.text "locale"
    t.text "sort"
    t.integer "forum_id"
    t.text "structure_ids"
    t.boolean "comments_disabled"
    t.boolean "organizational_on_top"
    t.boolean "disable_teacher_display", default: false
    t.integer "submission_max_team_size"
    t.integer "submission_grace_period", default: 15
    t.boolean "legacy_seminar", default: false
    t.integer "annotations_status", default: 1, null: false
    t.index ["teacher_id"], name: "index_lectures_on_teacher_id"
    t.index ["term_id"], name: "index_lectures_on_term_id"
  end

  create_table "lesson_section_joins", force: :cascade do |t|
    t.integer "lesson_id"
    t.integer "section_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["lesson_id"], name: "index_lesson_section_joins_on_lesson_id"
    t.index ["section_id"], name: "index_lesson_section_joins_on_section_id"
  end

  create_table "lesson_tag_joins", force: :cascade do |t|
    t.integer "lesson_id"
    t.integer "tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["lesson_id"], name: "index_lesson_tag_joins_on_lesson_id"
    t.index ["tag_id"], name: "index_lesson_tag_joins_on_tag_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.date "date"
    t.integer "lecture_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "start_destination"
    t.text "end_destination"
    t.text "details"
    t.index ["lecture_id"], name: "index_lessons_on_lecture_id"
  end

  create_table "links", force: :cascade do |t|
    t.bigint "medium_id"
    t.bigint "linked_medium_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["linked_medium_id"], name: "index_links_on_linked_medium_id"
    t.index ["medium_id", "linked_medium_id"], name: "index_links_on_medium_id_and_linked_medium_id", unique: true
    t.index ["medium_id"], name: "index_links_on_medium_id"
  end

  create_table "media", force: :cascade do |t|
    t.text "external_reference_link"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "sort"
    t.string "description"
    t.string "teachable_type"
    t.bigint "teachable_id"
    t.text "video_data"
    t.text "screenshot_data"
    t.text "manuscript_data"
    t.text "released"
    t.boolean "imported_manuscript"
    t.string "quizzable_type"
    t.bigint "quizzable_id"
    t.text "hint"
    t.integer "parent_id"
    t.text "quiz_graph"
    t.integer "level"
    t.text "type"
    t.text "text"
    t.boolean "independent"
    t.text "locale"
    t.text "solution"
    t.text "question_sort"
    t.text "content"
    t.text "geogebra_data"
    t.text "geogebra_app_name"
    t.integer "position"
    t.boolean "text_input", default: false
    t.float "boost", default: 0.0
    t.datetime "released_at", precision: nil
    t.text "publisher"
    t.datetime "file_last_edited", precision: nil
    t.text "external_link_description"
    t.integer "annotations_status", default: -1, null: false
    t.index ["quizzable_type", "quizzable_id"], name: "index_media_on_quizzable_type_and_quizzable_id"
    t.index ["teachable_type", "teachable_id"], name: "index_media_on_teachable_type_and_teachable_id"
  end

  create_table "medium_tag_joins", force: :cascade do |t|
    t.bigint "medium_id"
    t.bigint "tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["medium_id"], name: "index_medium_tag_joins_on_medium_id"
    t.index ["tag_id"], name: "index_medium_tag_joins_on_tag_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "recipient_id"
    t.integer "notifiable_id"
    t.text "notifiable_type"
    t.text "action"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["notifiable_id", "notifiable_type"], name: "index_notifications_on_notifiable_id_and_notifiable_type"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "notions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title"
    t.text "locale"
    t.integer "tag_id"
    t.integer "aliased_tag_id"
    t.index ["aliased_tag_id"], name: "index_notions_on_aliased_tag_id"
    t.index ["tag_id"], name: "index_notions_on_tag_id"
  end

  create_table "program_translations", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.index ["locale"], name: "index_program_translations_on_locale"
    t.index ["program_id"], name: "index_program_translations_on_program_id"
  end

  create_table "programs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "subject_id"
    t.index ["subject_id"], name: "index_programs_on_subject_id"
  end

  create_table "quiz_certificates", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "user_id"
    t.text "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_quiz_certificates_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_certificates_on_user_id"
  end

  create_table "readers", force: :cascade do |t|
    t.integer "user_id"
    t.integer "thread_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "redemptions", force: :cascade do |t|
    t.uuid "voucher_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_redemptions_on_user_id"
    t.index ["voucher_id"], name: "index_redemptions_on_voucher_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.text "start_time"
    t.text "end_time"
    t.text "explanation"
    t.bigint "item_id"
    t.bigint "medium_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_referrals_on_item_id"
    t.index ["medium_id"], name: "index_referrals_on_medium_id"
  end

  create_table "relations", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "related_tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["related_tag_id"], name: "index_relations_on_related_tag_id"
    t.index ["tag_id", "related_tag_id"], name: "index_relations_on_tag_id_and_related_tag_id", unique: true
    t.index ["tag_id"], name: "index_relations_on_tag_id"
  end

  create_table "section_tag_joins", force: :cascade do |t|
    t.integer "section_id"
    t.integer "tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "tag_position"
    t.index ["section_id"], name: "index_section_tag_joins_on_section_id"
    t.index ["tag_id"], name: "index_section_tag_joins_on_tag_id"
  end

  create_table "sections", force: :cascade do |t|
    t.integer "chapter_id"
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "position"
    t.text "display_number"
    t.boolean "hidden"
    t.text "tags_order"
    t.text "details"
    t.index ["chapter_id"], name: "index_sections_on_chapter_id"
  end

  create_table "speaker_talk_joins", force: :cascade do |t|
    t.bigint "talk_id", null: false
    t.bigint "speaker_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["speaker_id"], name: "index_speaker_talk_joins_on_speaker_id"
    t.index ["talk_id"], name: "index_speaker_talk_joins_on_talk_id"
  end

  create_table "subject_translations", force: :cascade do |t|
    t.bigint "subject_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.index ["locale"], name: "index_subject_translations_on_locale"
    t.index ["subject_id"], name: "index_subject_translations_on_subject_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "submissions", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "tutorial_id", null: false
    t.bigint "assignment_id", null: false
    t.text "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "manuscript_data"
    t.integer "invited_user_ids", default: [], array: true
    t.text "correction_data"
    t.datetime "last_modification_by_users_at", precision: nil
    t.boolean "accepted"
    t.index ["assignment_id"], name: "index_submissions_on_assignment_id"
    t.index ["token"], name: "index_submissions_on_token", unique: true
    t.index ["tutorial_id"], name: "index_submissions_on_tutorial_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "realizations"
  end

  create_table "talk_tag_joins", force: :cascade do |t|
    t.bigint "talk_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_talk_tag_joins_on_tag_id"
    t.index ["talk_id"], name: "index_talk_tag_joins_on_talk_id"
  end

  create_table "talks", force: :cascade do |t|
    t.bigint "lecture_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title"
    t.integer "position"
    t.text "details"
    t.date "dates", default: [], array: true
    t.text "description"
    t.boolean "display_description", default: false
    t.index ["lecture_id"], name: "index_talks_on_lecture_id"
  end

  create_table "terms", force: :cascade do |t|
    t.integer "year"
    t.string "season"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: false
    t.datetime "submission_deletion_mail", precision: nil
    t.datetime "submission_deletion_reminder", precision: nil
    t.datetime "submissions_deleted_at", precision: nil
  end

  create_table "thredded_categories", force: :cascade do |t|
    t.bigint "messageboard_id", null: false
    t.text "name", null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "slug", null: false
    t.index "lower(name) text_pattern_ops", name: "thredded_categories_name_ci"
    t.index ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true
    t.index ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
  end

  create_table "thredded_messageboard_groups", force: :cascade do |t|
    t.string "name"
    t.integer "position", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "messageboard_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_messageboard_users", force: :cascade do |t|
    t.bigint "thredded_user_detail_id", null: false
    t.bigint "thredded_messageboard_id", null: false
    t.datetime "last_seen_at", precision: nil, null: false
    t.index ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
    t.index ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary", unique: true
  end

  create_table "thredded_messageboards", force: :cascade do |t|
    t.text "name", null: false
    t.text "slug"
    t.text "description"
    t.integer "topics_count", default: 0
    t.integer "posts_count", default: 0
    t.integer "position", null: false
    t.bigint "last_topic_id"
    t.bigint "messageboard_group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "locked", default: false, null: false
    t.index ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
    t.index ["slug"], name: "index_thredded_messageboards_on_slug", unique: true
  end

  create_table "thredded_notifications_for_followed_topics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_notifications_for_private_topics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true
  end

  create_table "thredded_post_moderation_records", force: :cascade do |t|
    t.bigint "post_id"
    t.bigint "messageboard_id"
    t.text "post_content"
    t.bigint "post_user_id"
    t.text "post_user_name"
    t.bigint "moderator_id"
    t.integer "moderation_state", null: false
    t.integer "previous_moderation_state", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display", order: { created_at: :desc }
  end

  create_table "thredded_posts", force: :cascade do |t|
    t.bigint "user_id"
    t.text "content"
    t.string "source", limit: 191, default: "web"
    t.bigint "postable_id", null: false
    t.bigint "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index "to_tsvector('english'::regconfig, content)", name: "thredded_posts_content_fts", using: :gist
    t.index ["messageboard_id"], name: "index_thredded_posts_on_messageboard_id"
    t.index ["moderation_state", "updated_at"], name: "index_thredded_posts_for_display"
    t.index ["postable_id", "created_at"], name: "index_thredded_posts_on_postable_id_and_created_at"
    t.index ["postable_id"], name: "index_thredded_posts_on_postable_id"
    t.index ["user_id"], name: "index_thredded_posts_on_user_id"
  end

  create_table "thredded_private_posts", force: :cascade do |t|
    t.bigint "user_id"
    t.text "content"
    t.bigint "postable_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["postable_id", "created_at"], name: "index_thredded_private_posts_on_postable_id_and_created_at"
  end

  create_table "thredded_private_topics", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "last_user_id"
    t.text "title", null: false
    t.text "slug", null: false
    t.integer "posts_count", default: 0
    t.string "hash_id", limit: 20, null: false
    t.datetime "last_post_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_private_topics_on_last_post_at"
    t.index ["slug"], name: "index_thredded_private_topics_on_slug", unique: true
  end

  create_table "thredded_private_users", force: :cascade do |t|
    t.bigint "private_topic_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
    t.index ["user_id"], name: "index_thredded_private_users_on_user_id"
  end

  create_table "thredded_topic_categories", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_thredded_topic_categories_on_category_id"
    t.index ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"
  end

  create_table "thredded_topics", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "last_user_id"
    t.text "title", null: false
    t.text "slug", null: false
    t.bigint "messageboard_id", null: false
    t.integer "posts_count", default: 0, null: false
    t.boolean "sticky", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.string "hash_id", limit: 20, null: false
    t.integer "moderation_state", null: false
    t.datetime "last_post_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index "to_tsvector('english'::regconfig, title)", name: "thredded_topics_title_fts", using: :gist
    t.index ["hash_id"], name: "index_thredded_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_topics_on_last_post_at"
    t.index ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
    t.index ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display", order: { sticky: :desc, updated_at: :desc }
    t.index ["slug"], name: "index_thredded_topics_on_slug", unique: true
    t.index ["user_id"], name: "index_thredded_topics_on_user_id"
  end

  create_table "thredded_user_details", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "latest_activity_at", precision: nil
    t.integer "posts_count", default: 0
    t.integer "topics_count", default: 0
    t.datetime "last_seen_at", precision: nil
    t.integer "moderation_state", default: 0, null: false
    t.datetime "moderation_state_changed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
    t.index ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations", order: { moderation_state_changed_at: :desc }
    t.index ["user_id"], name: "index_thredded_user_details_on_user_id", unique: true
  end

  create_table "thredded_user_messageboard_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "messageboard_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true
  end

  create_table "thredded_user_post_notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "notified_at", precision: nil, null: false
    t.index ["post_id"], name: "index_thredded_user_post_notifications_on_post_id"
    t.index ["user_id", "post_id"], name: "index_thredded_user_post_notifications_on_user_id_and_post_id", unique: true
  end

  create_table "thredded_user_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_thredded_user_preferences_on_user_id", unique: true
  end

  create_table "thredded_user_private_topic_read_states", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "postable_id", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.datetime "read_at", precision: nil, null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true
  end

  create_table "thredded_user_topic_follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "reason", limit: 2
    t.index ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true
  end

  create_table "thredded_user_topic_read_states", force: :cascade do |t|
    t.bigint "messageboard_id", null: false
    t.bigint "user_id", null: false
    t.bigint "postable_id", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.datetime "read_at", precision: nil, null: false
    t.index ["messageboard_id"], name: "index_thredded_user_topic_read_states_on_messageboard_id"
    t.index ["user_id", "messageboard_id"], name: "thredded_user_topic_read_states_user_messageboard"
    t.index ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true
  end

  create_table "tutor_tutorial_joins", force: :cascade do |t|
    t.bigint "tutorial_id", null: false
    t.bigint "tutor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tutor_id"], name: "index_tutor_tutorial_joins_on_tutor_id"
    t.index ["tutorial_id"], name: "index_tutor_tutorial_joins_on_tutorial_id"
  end

  create_table "tutorials", force: :cascade do |t|
    t.text "title"
    t.bigint "lecture_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_tutorials_on_lecture_id"
  end

  create_table "user_favorite_lecture_joins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lecture_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_user_favorite_lecture_joins_on_lecture_id"
    t.index ["user_id"], name: "index_user_favorite_lecture_joins_on_user_id"
  end

  create_table "user_submission_joins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "submission_id"
    t.index ["submission_id"], name: "index_user_submission_joins_on_submission_id"
    t.index ["user_id"], name: "index_user_submission_joins_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin"
    t.integer "subscription_type"
    t.boolean "consents"
    t.datetime "consented_at", precision: nil
    t.text "name"
    t.text "homepage"
    t.boolean "no_notifications", default: false
    t.text "locale"
    t.boolean "email_for_medium"
    t.boolean "email_for_announcement"
    t.boolean "email_for_teachable"
    t.boolean "email_for_news"
    t.integer "current_lecture_id"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.boolean "unread_comments", default: false
    t.boolean "study_participant", default: false
    t.boolean "email_for_submission_upload"
    t.boolean "email_for_submission_removal"
    t.boolean "email_for_submission_join"
    t.boolean "email_for_submission_leave"
    t.boolean "email_for_correction_upload"
    t.boolean "email_for_submission_decision"
    t.text "name_in_tutorials"
    t.boolean "archived"
    t.datetime "locked_at", precision: nil
    t.text "image_data"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.date "deletion_date"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vignettes_answers", force: :cascade do |t|
    t.string "type"
    t.bigint "vignettes_question_id", null: false
    t.bigint "vignettes_slide_id", null: false
    t.bigint "vignettes_user_answer_id", null: false
    t.text "text"
    t.string "likert_scale_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vignettes_question_id"], name: "index_vignettes_answers_on_vignettes_question_id"
    t.index ["vignettes_slide_id"], name: "index_vignettes_answers_on_vignettes_slide_id"
    t.index ["vignettes_user_answer_id"], name: "index_vignettes_answers_on_vignettes_user_answer_id"
  end

  create_table "vignettes_answers_options", id: false, force: :cascade do |t|
    t.bigint "vignettes_answer_id", null: false
    t.bigint "vignettes_option_id", null: false
    t.index ["vignettes_answer_id", "vignettes_option_id"], name: "index_answers_options_on_answer_id_and_option_id"
    t.index ["vignettes_option_id", "vignettes_answer_id"], name: "index_answers_options_on_option_id_and_answer_id"
  end

  create_table "vignettes_codenames", force: :cascade do |t|
    t.string "pseudonym"
    t.bigint "user_id"
    t.bigint "lecture_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_vignettes_codenames_on_lecture_id"
    t.index ["user_id"], name: "index_vignettes_codenames_on_user_id"
  end

  create_table "vignettes_completion_messages", force: :cascade do |t|
    t.bigint "lecture_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_vignettes_completion_messages_on_lecture_id"
  end

  create_table "vignettes_info_slides", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "vignettes_questionnaire_id", null: false
    t.string "icon_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vignettes_questionnaire_id"], name: "index_vignettes_info_slides_on_vignettes_questionnaire_id"
  end

  create_table "vignettes_info_slides_slides", id: false, force: :cascade do |t|
    t.bigint "vignettes_info_slide_id", null: false
    t.bigint "vignettes_slide_id", null: false
    t.index ["vignettes_info_slide_id", "vignettes_slide_id"], name: "idx_on_vignettes_info_slide_id_vignettes_slide_id_2bdc65ab76"
    t.index ["vignettes_slide_id", "vignettes_info_slide_id"], name: "idx_on_vignettes_slide_id_vignettes_info_slide_id_c74f04e951"
  end

  create_table "vignettes_options", force: :cascade do |t|
    t.string "text"
    t.bigint "vignettes_question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vignettes_question_id"], name: "index_vignettes_options_on_vignettes_question_id"
  end

  create_table "vignettes_questionnaires", force: :cascade do |t|
    t.string "title"
    t.bigint "lecture_id", null: false
    t.boolean "published"
    t.boolean "editable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_vignettes_questionnaires_on_lecture_id"
  end

  create_table "vignettes_questions", force: :cascade do |t|
    t.string "type"
    t.text "question_text"
    t.bigint "vignettes_slide_id", null: false
    t.boolean "only_integer", default: false
    t.decimal "min_number", precision: 10
    t.decimal "max_number", precision: 10
    t.string "language", default: "en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vignettes_slide_id"], name: "index_vignettes_questions_on_vignettes_slide_id"
  end

  create_table "vignettes_slide_statistics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "vignettes_answer_id"
    t.integer "time_on_slide"
    t.integer "total_time_on_slide"
    t.text "time_on_info_slides"
    t.text "info_slides_access_count"
    t.text "info_slides_first_access_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vignettes_slide_statistics_on_user_id"
    t.index ["vignettes_answer_id"], name: "index_vignettes_slide_statistics_on_vignettes_answer_id"
  end

  create_table "vignettes_slides", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "vignettes_questionnaire_id", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_vignettes_slides_on_position"
    t.index ["vignettes_questionnaire_id"], name: "index_vignettes_slides_on_vignettes_questionnaire_id"
  end

  create_table "vignettes_user_answers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "vignettes_questionnaire_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vignettes_user_answers_on_user_id"
    t.index ["vignettes_questionnaire_id"], name: "index_vignettes_user_answers_on_vignettes_questionnaire_id"
  end

  create_table "votes", force: :cascade do |t|
    t.string "votable_type"
    t.bigint "votable_id"
    t.string "voter_type"
    t.bigint "voter_id"
    t.boolean "vote_flag"
    t.string "vote_scope"
    t.integer "vote_weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope"
    t.index ["votable_type", "votable_id"], name: "index_votes_on_votable_type_and_votable_id"
    t.index ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope"
    t.index ["voter_type", "voter_id"], name: "index_votes_on_voter_type_and_voter_id"
  end

  create_table "vouchers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "role", null: false
    t.bigint "lecture_id", null: false
    t.string "secure_hash", null: false
    t.datetime "invalidated_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_vouchers_on_lecture_id"
    t.index ["secure_hash"], name: "index_vouchers_on_secure_hash", unique: true
  end

  create_table "vtt_containers", force: :cascade do |t|
    t.text "table_of_contents_data"
    t.text "references_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "watchlist_entries", force: :cascade do |t|
    t.bigint "watchlist_id", null: false
    t.bigint "medium_id", null: false
    t.integer "medium_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medium_id"], name: "index_watchlist_entries_on_medium_id"
    t.index ["watchlist_id"], name: "index_watchlist_entries_on_watchlist_id"
  end

  create_table "watchlists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "watchlist_entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "public", default: false
    t.string "description"
    t.index ["user_id"], name: "index_watchlists_on_user_id"
    t.index ["watchlist_entry_id"], name: "index_watchlists_on_watchlist_entry_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "annotations", "media"
  add_foreign_key "annotations", "users"
  add_foreign_key "announcements", "lectures"
  add_foreign_key "announcements", "users", column: "announcer_id"
  add_foreign_key "assignments", "lectures"
  add_foreign_key "claims", "redemptions"
  add_foreign_key "commontator_comments", "commontator_comments", column: "parent_id", on_update: :restrict, on_delete: :cascade
  add_foreign_key "commontator_comments", "commontator_threads", column: "thread_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "commontator_subscriptions", "commontator_threads", column: "thread_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_self_joins", "courses"
  add_foreign_key "divisions", "programs"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "imports", "media"
  add_foreign_key "items", "media"
  add_foreign_key "items", "sections"
  add_foreign_key "lecture_user_joins", "lectures"
  add_foreign_key "lecture_user_joins", "users"
  add_foreign_key "links", "media"
  add_foreign_key "links", "media", column: "linked_medium_id"
  add_foreign_key "medium_tag_joins", "media"
  add_foreign_key "medium_tag_joins", "tags"
  add_foreign_key "programs", "subjects"
  add_foreign_key "quiz_certificates", "media", column: "quiz_id"
  add_foreign_key "quiz_certificates", "users"
  add_foreign_key "redemptions", "users"
  add_foreign_key "redemptions", "vouchers"
  add_foreign_key "referrals", "items"
  add_foreign_key "referrals", "media"
  add_foreign_key "speaker_talk_joins", "talks"
  add_foreign_key "speaker_talk_joins", "users", column: "speaker_id"
  add_foreign_key "submissions", "assignments"
  add_foreign_key "submissions", "tutorials"
  add_foreign_key "talk_tag_joins", "tags"
  add_foreign_key "talk_tag_joins", "talks"
  add_foreign_key "talks", "lectures"
  add_foreign_key "thredded_messageboard_users", "thredded_messageboards", on_delete: :cascade
  add_foreign_key "thredded_messageboard_users", "thredded_user_details", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "thredded_posts", column: "post_id", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "users", on_delete: :cascade
  add_foreign_key "tutor_tutorial_joins", "tutorials"
  add_foreign_key "tutor_tutorial_joins", "users", column: "tutor_id"
  add_foreign_key "tutorials", "lectures"
  add_foreign_key "user_favorite_lecture_joins", "lectures"
  add_foreign_key "user_favorite_lecture_joins", "users"
  add_foreign_key "user_submission_joins", "users"
  add_foreign_key "vignettes_answers", "vignettes_questions"
  add_foreign_key "vignettes_answers", "vignettes_slides"
  add_foreign_key "vignettes_answers", "vignettes_user_answers"
  add_foreign_key "vignettes_codenames", "lectures"
  add_foreign_key "vignettes_codenames", "users"
  add_foreign_key "vignettes_completion_messages", "lectures"
  add_foreign_key "vignettes_options", "vignettes_questions"
  add_foreign_key "vignettes_questionnaires", "lectures"
  add_foreign_key "vignettes_questions", "vignettes_slides"
  add_foreign_key "vignettes_slide_statistics", "users"
  add_foreign_key "vignettes_slide_statistics", "vignettes_answers"
  add_foreign_key "vignettes_slides", "vignettes_questionnaires"
  add_foreign_key "vignettes_user_answers", "users"
  add_foreign_key "vignettes_user_answers", "vignettes_questionnaires"
  add_foreign_key "vouchers", "lectures"
  add_foreign_key "watchlist_entries", "media"
  add_foreign_key "watchlist_entries", "watchlists"
  add_foreign_key "watchlists", "users"
  add_foreign_key "watchlists", "watchlist_entries"
end
