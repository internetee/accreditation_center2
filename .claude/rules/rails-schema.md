---
paths:
  - "db/schema.rb"
  - "db/migrate/**"
---

# Database Tables (12)

_Snapshot — may be stale after migrations. Use `rails_get_schema(table:"name")` for live data._

- **answers** (7 cols) — correct:boolean(=false), display_order:integer, text_en:text, text_et:text
- **practical_task_results** (8 cols) — inputs:jsonb(={}), result:jsonb(={}), status:string(=pending), validated_at:datetime | FK: practical_task_id→practical_tasks, test_attempt_id→test_attempts | Idx: test_attempt_id+practical_task_id(unique)
  status: pending, running, passed, failed
- **practical_tasks** (10 cols) — active:boolean(=true), body_en:text, body_et:text, display_order:integer(=0), title_en:string, title_et:string, validator:jsonb(={}) | FK: test_id→tests
- **question_responses** (6 cols) — marked_for_later:boolean(=false), selected_answer_ids:integer[](=[]) | FK: test_attempt_id→test_attempts | Idx: test_attempt_id+question_id(unique)
- **questions** (11 cols) — active:boolean(=true), display_order:integer, help_text_en:text, help_text_et:text, mandatory_to:date, question_type:string(=multiple_choice), text_en:text, text_et:text | FK: test_category_id→test_categories | Idx: test_category_id+display_order(unique)
  question_type: multiple_choice
- **registrar_notification_events** (6 cols) — cycle_key:string, event_type:string, sent_at:datetime | FK: registrar_id→registrars | Idx: registrar_id+event_type+cycle_key(unique)
- **registrars** (6 cols) — accreditation_date:datetime, accreditation_expire_date:datetime, email:string, name:string | Idx: lower((name)::text)(unique)
- **test_attempts** (10 cols) — access_code:string, completed_at:datetime, passed:boolean, score_percentage:integer, started_at:datetime, vars:jsonb(={}) | FK: test_id→tests, user_id→users | Idx: access_code(unique)
- **test_categories** (10 cols) — active:boolean(=true), description_en:text, description_et:text, domain_rule_reference:string, domain_rule_url:string, name_en:string, name_et:string, questions_per_category:integer(=5)
- **test_categories_tests** (3 cols) — display_order:integer(=0) | FK: test_category_id→test_categories, test_id→tests | Idx: test_id+display_order(unique), test_id+test_category_id(unique)
- **tests** (12 cols) — active:boolean(=true), auto_assign:boolean(=false), description_en:text, description_et:text, passing_score_percentage:integer(=70), slug:string, test_type:integer(=0), time_limit_minutes:integer(=60), title_en:string, title_et:string | Idx: slug(unique)
  test_type: theoretical, practical
- **users** (17 cols) — current_sign_in_at:datetime, current_sign_in_ip:string, email:string, encrypted_password:string(=""), last_sign_in_at:datetime, last_sign_in_ip:string, name:string, provider:string, reset_password_sent_at:datetime, reset_password_token:string, role:integer, sign_in_count:integer, uid:string, username:string | FK: registrar_id→registrars | Idx: provider+uid(unique), reset_password_token(unique), username(unique)
  role: user, admin