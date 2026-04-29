---
paths:
  - "app/models/**/*.rb"
---

# ActiveRecord Models (12)

_Quick reference — use `rails_get_model_details(model:"Name")` for live data with resolved concerns and callbacks._

- Answer (table: answers) — 1 assocs, 3 validations
  scopes: correct, incorrect, ordered
  methods: text, correct?, question
- PracticalTask (table: practical_tasks) — 2 assocs, 5 validations
  scopes: ordered, active
  methods: vconf, klass_name, conf, input_fields, body, body?, practical_task_results, prior_display_order, subsequent_display_order, test, title, title?, translatable_attributes, translatable_attributes?
- PracticalTaskResult (table: practical_task_results) — 2 assocs, 2 validations
  methods: correct?, save_running_status!, persist_result!, feedback, set_feedback, feedback_by_name, failed!, failed?, passed!, passed?, pending!, pending?, practical_task, running!, running?, test_attempt
  status: pending, running, passed, failed
- Question (table: questions) — 3 assocs, 7 validations
  scopes: ordered, active, mandatory, non_mandatory
  methods: mandatory_only_if_active, update_mandatory_to, multiple_choice?, correct_answers, correct_answer_ids, correct_answer_count, randomize_answers, mandatory?, answers, help_text, help_text?, mandatory, multiple_choice!, prior_display_order, question_responses, subsequent_display_order, test_category, text, text?, translatable_attributes
  question_type: multiple_choice
- QuestionResponse (table: question_responses) — 2 assocs, 2 validations
  scopes: answered
  methods: selected_answers, correct?, partially_correct?, answered?, status, question, test_attempt
- Registrar (table: registrars) — 3 assocs, 4 validations
  scopes: with_non_admin_users
  methods: accreditation_expired?, accreditation_expires_soon?, days_until_accreditation_expiry, registrar_notification_events, test_attempts, users
- RegistrarNotificationEvent (table: registrar_notification_events) — 1 assocs, 3 validations
  methods: registrar
- Test (table: tests) — 5 assocs, 8 validations
  scopes: active, auto_assignable
  methods: auto_assign_check, active_ordered_test_categories_with_join_id, total_questions, estimated_duration, theoretical_questions_count, practical_tasks_count, total_components, build_duplicate, description, description?, friendly_id, friendly_id_config, normalize_friendly_id, practical!, practical?, practical_tasks, questions, resolve_friendly_id_conflict, should_generate_new_friendly_id?, test_attempts
  test_type: theoretical, practical
- TestAttempt (table: test_attempts) — 6 assocs, 4 validations
  scopes: ordered, not_completed, completed, in_progress, recent, passed, failed
  methods: questions_have_answers, merge_vars!, set_started_at, complete!, score_percentage, completed?, not_started?, in_progress?, failed?, time_remaining, time_elapsed, time_warning?, time_expired?, answered_questions, unanswered_questions, marked_for_later, completed_tasks, incompleted_tasks, progress_percentage, all_questions_answered?
- TestCategoriesTest (table: test_categories_tests) — 2 assocs, 3 validations
  methods: prior_display_order, subsequent_display_order, test, test_category
- TestCategory (table: test_categories) — 3 assocs, 4 validations
  scopes: active
  methods: name_with_rule, description, description?, name, name?, questions, test_categories_tests, tests, translatable_attributes, translatable_attributes?
- User (table: users) — 3 assocs, 6 validations
  scopes: not_admin, admin
  methods: admin_password_required?, assign_registrar_from_api!, set_default_role, first_sign_in?, last_sign_in_ip_address, current_sign_in_ip_address, passed_tests, failed_tests, completed_tests, in_progress_tests, can_take_test?, test_history, test_statistics, display_name, admin?, user?, admin!, devise_saved_change_to_email?, devise_saved_change_to_encrypted_password?, devise_unconfirmed_email_will_change!
  role: user, admin