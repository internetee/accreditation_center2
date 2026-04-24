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

ActiveRecord::Schema[8.1].define(version: 2026_04_24_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answers", force: :cascade do |t|
    t.boolean "correct", default: false
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.bigint "question_id", null: false
    t.text "text_en", null: false
    t.text "text_et", null: false
    t.datetime "updated_at", null: false
    t.index ["correct"], name: "index_answers_on_correct"
    t.index ["display_order"], name: "index_answers_on_display_order"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "practical_task_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "inputs", default: {}
    t.bigint "practical_task_id", null: false
    t.jsonb "result", default: {}
    t.string "status", default: "pending", null: false
    t.bigint "test_attempt_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "validated_at"
    t.index ["status"], name: "index_practical_task_results_on_status"
    t.index ["test_attempt_id", "practical_task_id"], name: "idx_ptr_on_attempt_and_task", unique: true
  end

  create_table "practical_tasks", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "body_en", null: false
    t.text "body_et", null: false
    t.datetime "created_at", null: false
    t.integer "display_order", default: 0, null: false
    t.bigint "test_id", null: false
    t.string "title_en"
    t.string "title_et"
    t.datetime "updated_at", null: false
    t.jsonb "validator", default: {}
    t.index ["display_order"], name: "index_practical_tasks_on_display_order"
    t.index ["test_id"], name: "index_practical_tasks_on_test_id"
  end

  create_table "question_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "marked_for_later", default: false
    t.bigint "question_id", null: false
    t.integer "selected_answer_ids", default: [], array: true
    t.bigint "test_attempt_id", null: false
    t.datetime "updated_at", null: false
    t.index ["marked_for_later"], name: "index_question_responses_on_marked_for_later"
    t.index ["question_id"], name: "index_question_responses_on_question_id"
    t.index ["selected_answer_ids"], name: "index_question_responses_on_selected_answer_ids", using: :gin
    t.index ["test_attempt_id", "question_id"], name: "index_question_responses_on_test_attempt_id_and_question_id", unique: true
    t.index ["test_attempt_id"], name: "index_question_responses_on_test_attempt_id"
  end

  create_table "questions", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.text "help_text_en"
    t.text "help_text_et"
    t.date "mandatory_to"
    t.string "question_type", default: "multiple_choice", null: false
    t.bigint "test_category_id", null: false
    t.text "text_en", null: false
    t.text "text_et", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_questions_on_active"
    t.index ["mandatory_to"], name: "index_questions_on_mandatory_to"
    t.index ["question_type"], name: "index_questions_on_question_type"
    t.index ["test_category_id", "display_order"], name: "index_questions_on_test_category_id_and_display_order", unique: true
    t.index ["test_category_id"], name: "index_questions_on_test_category_id"
  end

  create_table "registrars", force: :cascade do |t|
    t.datetime "accreditation_date"
    t.datetime "accreditation_expire_date"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_registrars_on_lower_name", unique: true
  end

  create_table "test_attempts", force: :cascade do |t|
    t.string "access_code", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.boolean "passed"
    t.integer "score_percentage"
    t.datetime "started_at"
    t.bigint "test_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.jsonb "vars", default: {}, null: false
    t.index ["access_code"], name: "index_test_attempts_on_access_code", unique: true
    t.index ["completed_at"], name: "index_test_attempts_on_completed_at"
    t.index ["passed"], name: "index_test_attempts_on_passed"
    t.index ["started_at"], name: "index_test_attempts_on_started_at"
    t.index ["test_id"], name: "index_test_attempts_on_test_id"
    t.index ["user_id"], name: "index_test_attempts_on_user_id"
    t.index ["vars"], name: "index_test_attempts_on_vars", using: :gin
  end

  create_table "test_categories", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description_en"
    t.text "description_et"
    t.string "domain_rule_reference"
    t.string "domain_rule_url"
    t.string "name_en", null: false
    t.string "name_et", null: false
    t.integer "questions_per_category", default: 5, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_test_categories_on_active"
    t.index ["domain_rule_reference"], name: "index_test_categories_on_domain_rule_reference"
  end

  create_table "test_categories_tests", force: :cascade do |t|
    t.integer "display_order", default: 0, null: false
    t.bigint "test_category_id", null: false
    t.bigint "test_id", null: false
    t.index ["test_category_id"], name: "index_test_categories_tests_on_test_category_id"
    t.index ["test_id", "display_order"], name: "index_test_categories_tests_on_test_id_and_display_order", unique: true
    t.index ["test_id", "test_category_id"], name: "index_test_categories_tests_on_test_id_and_test_category_id", unique: true
    t.index ["test_id"], name: "index_test_categories_tests_on_test_id"
  end

  create_table "tests", force: :cascade do |t|
    t.boolean "active", default: true
    t.boolean "auto_assign", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description_en"
    t.text "description_et"
    t.integer "passing_score_percentage", default: 70, null: false
    t.string "slug"
    t.integer "test_type", default: 0, null: false
    t.integer "time_limit_minutes", default: 60, null: false
    t.string "title_en", null: false
    t.string "title_et", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_tests_on_active"
    t.index ["slug"], name: "index_tests_on_slug", unique: true
    t.index ["test_type"], name: "index_tests_on_test_type"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.string "provider"
    t.bigint "registrar_id"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.integer "sign_in_count"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["registrar_id"], name: "index_users_on_registrar_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true, where: "(username IS NOT NULL)"
  end

  add_foreign_key "practical_task_results", "practical_tasks"
  add_foreign_key "practical_task_results", "test_attempts"
  add_foreign_key "practical_tasks", "tests"
  add_foreign_key "question_responses", "test_attempts"
  add_foreign_key "questions", "test_categories"
  add_foreign_key "test_attempts", "tests"
  add_foreign_key "test_attempts", "users"
  add_foreign_key "test_categories_tests", "test_categories"
  add_foreign_key "test_categories_tests", "tests"
  add_foreign_key "users", "registrars"
end
