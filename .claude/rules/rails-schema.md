---
paths:
  - "db/schema.rb"
  - "db/migrate/**"
---

# Database Tables (10)

_Snapshot — may be stale after migrations. Use `rails_get_schema(table:"name")` for live data._

- **answers** (7 cols) — text_et:text, text_en:text, display_order:integer, correct:boolean(=false)
- **practical_task_results** (8 cols) — status:string(=pending), inputs:jsonb(={}), result:jsonb(={}), validated_at:datetime | FK: practical_task_id→practical_tasks, test_attempt_id→test_attempts | Idx: test_attempt_id+practical_task_id(unique)
  status: pending, running, passed, failed
- **practical_tasks** (10 cols) — title_en:string, title_et:string, body_en:text, body_et:text, validator:jsonb(={}), display_order:integer(=0), active:boolean(=true) | FK: test_id→tests
- **question_responses** (6 cols) — selected_answer_ids:integer[](=[]), marked_for_later:boolean(=false) | FK: test_attempt_id→test_attempts | Idx: test_attempt_id+question_id(unique)
- **questions** (11 cols) — text_et:text, text_en:text, help_text_et:text, help_text_en:text, question_type:string(=multiple_choice), display_order:integer, active:boolean(=true), mandatory_to:date | FK: test_category_id→test_categories | Idx: test_category_id+display_order(unique)
  question_type: multiple_choice
- **test_attempts** (10 cols) — access_code:string, started_at:datetime, completed_at:datetime, score_percentage:integer, passed:boolean, vars:jsonb(={}) | FK: test_id→tests, user_id→users | Idx: access_code(unique)
- **test_categories** (10 cols) — name_et:string, name_en:string, description_et:text, description_en:text, domain_rule_reference:string, questions_per_category:integer(=5), active:boolean(=true), domain_rule_url:string
- **test_categories_tests** (3 cols) — display_order:integer(=0) | FK: test_category_id→test_categories, test_id→tests | Idx: test_id+display_order(unique), test_id+test_category_id(unique)
- **tests** (12 cols) — title_et:string, title_en:string, description_et:text, description_en:text, time_limit_minutes:integer(=60), passing_score_percentage:integer(=70), active:boolean(=true), slug:string, test_type:integer(=0), auto_assign:boolean(=false) | Idx: slug(unique)
  test_type: theoretical, practical
- **users** (19 cols) — email:string(=""), role:integer, sign_in_count:integer, current_sign_in_at:datetime, last_sign_in_at:datetime, current_sign_in_ip:string, last_sign_in_ip:string, registrar_name:string, registrar_accreditation_date:datetime, registrar_accreditation_expire_date:datetime, provider:string, uid:string, name:string, username:string, encrypted_password:string(=""), reset_password_token:string, reset_password_sent_at:datetime | Idx: provider+uid(unique), reset_password_token(unique), username(unique)
  role: user, admin