# Registrar accreditation flows

This document describes how registrar accreditation and reaccreditation work in **accreditation_center2**, including sync to REPP, test requirements, the 30-day window, and email notifications.

Implementation lives mainly in:

- `app/services/registrar_accreditation_eligibility.rb`
- `app/models/test_attempt.rb` (`enqueue_accreditation_sync_if_complete`, `after_commit`)
- `app/jobs/accreditation_sync_job.rb`
- `app/services/accreditation_results_service.rb`
- `app/services/registrar_accreditation_notifications_service.rb`

---

## Key concepts (three different “accredited” meanings)

| Concept | Meaning | How it is determined |
|--------|---------|----------------------|
| **A. Previously accredited in portal** | Registrar already known from REPP or prior sync | `accreditation_date` **or** `accreditation_expire_date` present in accreditation DB |
| **B. Portal test–accredited** | Both tests passed in portal | At least one passed+completed **theoretical** and one **practical** attempt (any users on registrar) |
| **C. REPP reaccredited (dates updated)** | Registry dates actually renewed | `AccreditationSyncJob` → REPP `push_results` succeeds → portal dates updated from API |

**Assignment:** Users can still be assigned **both** tests when `AUTO_ASSIGN_TEST_ATTEMPTS=true`. Assignment does **not** depend on accreditation status.

---

## 1) When is `AccreditationSyncJob` enqueued?

Triggered when a **passed** attempt is first completed:

1. `TestAttempt#complete!` saves `completed_at` and `passed`
2. `after_commit` runs `enqueue_accreditation_sync_if_complete` (only when `completed_at` changed)
3. Job is enqueued as `AccreditationSyncJob.perform_later(registrar, test_attempt.id)`

The attempt id is passed so the job can evaluate eligibility using the **completing attempt** (`triggering_attempt`), even if Solid Queue runs inline inside the same Puma request before a fresh DB query would see the new pass.

**Enqueue rules** (unchanged):

| # | Prior portal dates (A) | Portal tests (B) | Attempt just passed | Job enqueued? |
|---|------------------------|------------------|---------------------|---------------|
| 1 | No | No theory / no practical | Theoretical | No |
| 2 | No | No theory / no practical | Practical | No |
| 3 | No | Theory only | Theoretical | No |
| 4 | No | Practical only | Practical | No |
| 5 | No | **Both** theory + practical | Theoretical | **Yes** |
| 6 | No | **Both** theory + practical | Practical (first practical pass) | **Yes** |
| 7 | No | **Both** | Practical (another practical pass already exists) | No |
| 8 | **Yes** (date or expire from REPP) | No portal passes | Theoretical | **Yes** (reaccreditation path) |
| 9 | **Yes** | No portal passes | Practical | No |
| 10 | **Yes** | Theory only (no practical in portal) | Theoretical | **Yes** |
| 11 | **Yes** | **Both** | Theoretical | **Yes** |
| 12 | **Yes** | **Both** | Practical (extra pass) | No (deduped) |

At enqueue time, eligibility is built with `triggering_attempt: self` so the row being completed counts toward `accredited?` and `last_theory_passed_at`.

---

## 2) When does REPP sync actually run?

`AccreditationSyncJob` loads the registrar and (when provided) the completing attempt, then calls `AccreditationResultsService#sync_registrar_accreditation(registrar, triggering_attempt:)`.

Sync proceeds when `RegistrarAccreditationEligibility#sync_eligible?` is true. For jobs enqueued from test completion, eligibility again receives `triggering_attempt` so the just-finished pass is included.

| # | Portal dates (A) | Portal theory pass | Portal practical pass | `sync_eligible?` | REPP updated? |
|---|------------------|--------------------|-----------------------|------------------|---------------|
| 1 | No | No | No | No | No — `"Registrar not accredited"` |
| 2 | No | Yes | No | No | No |
| 3 | No | No | Yes | No | No |
| 4 | No | Yes | Yes | **Yes** (initial accreditation) | **Yes**, if API OK |
| 5 | **Yes** | Yes | No | **Yes** (reaccreditation) | **Yes**, if API OK |
| 6 | **Yes** | Yes | Yes | **Yes** | **Yes**, if API OK |
| 7 | **Yes** | No | No | No | No |
| 8 | **Yes** | No | Yes | No | No |

REPP receives `last_theory_test_passed_at` (latest theoretical pass `completed_at`). Practical results are **not** sent to REPP for renewal.

---

## 3) First-time vs reaccreditation

| Scenario | Portal before tests | Tests required for **REPP sync** | Practical required for sync? |
|----------|---------------------|----------------------------------|------------------------------|
| **First accreditation** (new in portal, no REPP dates) | No dates | Theoretical **and** practical pass in portal | **Yes** |
| **Reaccreditation** (imported from REPP) | Date and/or expire from login | **Theoretical pass only** | **No** (for sync; users may still take practical if assigned) |
| **Reaccreditation** (portal passes + REPP dates) | Dates + optional both passes | Theoretical pass enough to enqueue/sync | **No** for sync trigger |

### 30-day reaccreditation window (emails only)

Applies to **emails after successful sync**, not to whether sync runs.

- **Window:** new `accreditation_date` (after sync) must be between `(previous_expire − 30 days)` and `previous_expire` (`REACCREDITATION_WINDOW_DAYS = 30`).
- **Outside window:** sync may still update REPP dates, but **no** `reaccreditation_granted` or admin window mails.

---

## 4) Login / import from REPP

| Event | What happens |
|-------|----------------|
| User logs in (OIDC → REPP `tara_callback`) | Registrar created/found by name; `accreditation_date` / `accreditation_expire_date` copied from REPP when present |
| `AUTO_ASSIGN_TEST_ATTEMPTS=true` | Both theoretical and practical attempts assigned if user has no active (non-expired) attempt per type |

---

## 5) Emails on test completion

`RegistrarAccreditationNotificationsService#notify_test_completion`

Sent only if the attempt **passed** and the registrar is **not** covered by `skip_partial_accreditation_notice?` (portal test–accredited **or** previously accredited in system from REPP).

| # | Portal dates (A) | Portal tests (B) | Test passed | Email |
|---|------------------|------------------|-------------|--------|
| 1 | No | Neither / one only | Theoretical | `theoretical_passed_not_accredited` (once per cycle) |
| 2 | No | Neither / one only | Practical | `practical_passed_not_accredited` (once per cycle) |
| 3 | No | **Both** | Either | **None** |
| 4 | **Yes** (REPP import) | Any / none | Theoretical or practical | **None** |
| 5 | **Yes** | Theory only | Theoretical | **None** |

---

## 6) Emails after successful REPP sync

`RegistrarAccreditationNotificationsService#notify_accreditation_sync`

| Prior `accreditation_date` | Prior `accreditation_expire_date` | New date within 30-day window before prior expire? | Emails |
|----------------------------|-----------------------------------|-----------------------------------------------------|--------|
| Blank | Blank | N/A (first time) | `accreditation_granted_or_reaccredited` (first) + `admin_accreditation_window_notice` |
| Present | Blank | — | Reaccreditation branch skipped (no expire → no window mails) |
| Any | Present | **Yes** | `accreditation_granted_or_reaccredited` (reaccreditation) + `admin_accreditation_window_notice` |
| Any | Present | **No** | **None** from sync notifier |

All notification types are deduplicated via `registrar_notification_events` (once per cycle key).

---

## 7) Scheduled expiry emails

`notify_daily_expiry_checks` / `ExpiryCheckJob`

| Condition (on `reference_date`) | Email |
|--------------------------------|--------|
| `expire_date == today + 30 days` | `expiry_30_days` (once per expiry cycle) |
| `expire_date <= today` | `expiry_or_passed` (once per expiry cycle) |

These are renewal reminders; they do **not** perform accreditation sync.

---

## 8) End-to-end flows

### A) Brand-new registrar in portal (no REPP dates)

1. Login → no accreditation dates.
2. Auto-assign → theoretical + practical (if enabled).
3. Pass theoretical → email “need practical”; **no** sync.
4. Pass practical (first time; both types now passed) → **sync job** → REPP dates set → **first accreditation** emails.

### B) Registrar accredited in REPP, first time in portal

1. Login → dates imported (`previously_accredited_in_system?` = true).
2. Auto-assign → still both tests.
3. Pass theoretical only → **sync job** → REPP updated → reaccreditation emails **only if** within 30-day window vs **previous** expire.
4. No “need practical” email on theoretical pass.

### C) Already portal-accredited + REPP dates

1. Pass another theoretical → sync runs.
2. Pass another practical → usually **no** sync (dedupe).
3. No partial-accreditation emails.

### D) Manual admin sync

Admin → Jobs → “Accreditation sync” enqueues `AccreditationSyncJob.perform_later(registrar)` with **no** `triggering_attempt_id`. Eligibility is evaluated from DB state only — same rules as [section 2](#2-when-does-repp-sync-actually-run).

---

## 9) UI status (portal display)

Based on `Registrar#accreditation_expire_date` (not test history):

| `accreditation_expire_date` | UI status |
|----------------------------|-----------|
| Blank | Not accredited |
| Future, more than 30 days left | Accredited |
| Future, within 30 days | Expires soon |
| Past | Expired |

---

## Quick reference: reaccreditation checklist

| Step | Required? |
|------|-----------|
| Registrar has `accreditation_date` or `accreditation_expire_date` in portal (from REPP) | **Yes** |
| User passes theoretical test | **Yes** |
| User passes practical test | **No** (for sync) |
| Within 30 days before previous expire | **Only** for reaccreditation confirmation emails, not for sync |

---

## Troubleshooting

If reaccreditation does not work in production, check in order:

1. Portal registrar has `accreditation_date` or `accreditation_expire_date` after login.
2. Theoretical attempt is `passed`, `completed`, and has `started_at` set (`completed` scope requires both `started_at` and `completed_at`).
3. Application logs / job queue for `AccreditationSyncJob` — look for `"Registrar not accredited"` vs a successful REPP call.
4. **Puma actually restarted after deploy.** A long-running Puma process may still run old code in memory while `rails runner` loads the current release. Restart the same process that serves HTTP (not only `touch tmp/restart.txt` if that does not reach it).
5. **Solid Queue in Puma** (`SOLID_QUEUE_IN_PUMA=true`) runs jobs inside the web process; sync after test completion depends on `triggering_attempt` being passed from the enqueue path.
6. REPP `POST /repp/v1/registrar/accreditation/push_results` response.
7. Whether reaccreditation **emails** were expected but blocked by the 30-day window (sync may still succeed).

---

## Eligibility API summary

`RegistrarAccreditationEligibility.new(registrar, triggering_attempt: nil)` — optional `triggering_attempt` is the completing `TestAttempt` passed from the sync job. When set, that attempt counts toward `accredited?` and `last_theory_passed_at` even if association queries in the same request would not yet return it.

| Method | True when |
|--------|-----------|
| `accredited?` | Both theoretical and practical passed attempts exist on registrar (including `triggering_attempt` when applicable) |
| `previously_accredited_in_system?` | `accreditation_date` or `accreditation_expire_date` present |
| `reaccreditation_eligible?` | Previously accredited in system **and** at least one theoretical pass (`last_theory_passed_at` present) |
| `sync_eligible?` | `accredited?` **or** `reaccreditation_eligible?` |
| `can_sync_from_theoretical?` | Previously accredited in system **or** `accredited?` |
| `skip_partial_accreditation_notice?` | `accredited?` **or** previously accredited in system |
