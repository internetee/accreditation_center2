require 'rails_helper'

RSpec.describe TestAttempt, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let!(:theoretical_test) { create(:test, :theoretical, time_limit_minutes: 60, passing_score_percentage: 60) }
  let!(:test_category) { create(:test_category) }
  let!(:question) { create(:question, test_category: test_category) }
  let!(:answer) { create(:answer, question: question, correct: true) }
  let!(:test_categories_test) { create(:test_categories_test, test: theoretical_test, test_category: test_category) }
  let!(:practical_test) { create(:test, :practical, time_limit_minutes: 30, passing_score_percentage: 100) }

  describe 'validations' do
    it 'validates questions_have_answers if test is theoretical' do
      attempt = build(:test_attempt, user: user, test: theoretical_test)
      expect(attempt.valid?).to be(true)

      test_category.questions.destroy_all
      expect(attempt.valid?).to be(false)
    end

    it 'validates access_code presence' do
      attempt = build(:test_attempt, user: user, test: theoretical_test, access_code: nil)
      expect(attempt.valid?).to be(false)
      expect(attempt.errors[:access_code]).to be_present

      attempt = build(:test_attempt, user: user, test: theoretical_test, access_code: '123456')
      expect(attempt.valid?).to be(true)
    end

    it 'validates access_code uniqueness' do
      attempt = create(:test_attempt, user: user, test: theoretical_test, access_code: '123456')
      expect(attempt.valid?).to be(true)

      attempt = build(:test_attempt, user: user, test: theoretical_test, access_code: '123456')
      expect(attempt.valid?).to be(false)
      expect(attempt.errors[:access_code]).to be_present
    end
  end

  describe 'scopes' do
    it 'filters by status scopes' do
      a_in_progress = create(:test_attempt, user: user, test: theoretical_test, started_at: Time.current, completed_at: nil, passed: false)
      a_completed   = create(:test_attempt, :completed, user: user, test: theoretical_test, passed: false)
      a_passed      = create(:test_attempt, :passed, user: user, test: theoretical_test)
      a_old         = create(:test_attempt, :completed, user: user, test: theoretical_test, passed: false, created_at: 40.days.ago)

      expect(described_class.in_progress).to include(a_in_progress)
      expect(described_class.completed).to include(a_completed, a_passed)
      expect(described_class.passed).to include(a_passed)
      expect(described_class.failed).to include(a_completed)
      expect(described_class.recent).not_to include(a_old)
      expect(described_class.not_completed).to include(a_in_progress)
    end
  end

  describe 'state transitions' do
    it 'sets completed_at in complete!' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      expect(attempt.completed?).to be(false)

      expect { attempt.complete! }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(attempt.completed?).to be(true)
    end

    it 'syncs accreditation when user completes both theoretical and practical tests' do
      # First, create a passed theoretical attempt
      create(:test_attempt, user: user, test: theoretical_test, passed: true, completed_at: 1.hour.ago)

      # Now complete practical test with passing score
      practical_attempt = create(:test_attempt, user: user, test: practical_test)

      # Setup practical test to pass (all tasks passed = 100% score)
      task1 = create(:practical_task, test: practical_test)
      task2 = create(:practical_task, test: practical_test)
      create(:practical_task_result, test_attempt: practical_attempt, practical_task: task1, status: 'passed')
      create(:practical_task_result, test_attempt: practical_attempt, practical_task: task2, status: 'passed')

      expect {
        practical_attempt.complete!
      }.to have_enqueued_job(AccreditationSyncJob).with(user.id)
    end

    it 'does not sync when test is not passed' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      # Setup to fail - no question responses means 0% score, which is below 60% threshold
      # This will cause passed? to return false

      expect {
        attempt.complete!
      }.not_to have_enqueued_job(AccreditationSyncJob)
    end

    it 'does not sync when only one test type is passed' do
      # Complete only theoretical test - setup to pass
      theoretical_attempt = create(:test_attempt, user: user, test: theoretical_test)
      create(:question_response, test_attempt: theoretical_attempt, question: question, selected_answer_ids: [answer.id])

      expect {
        theoretical_attempt.complete!
      }.not_to have_enqueued_job(AccreditationSyncJob)
    end
  end

  describe 'timing helpers' do
    it 'computes time_remaining correctly' do
      # Freeze time to test exact values
      frozen_time = Time.zone.parse('2024-01-01 12:00:00')
      travel_to frozen_time do
        # Not started - should return full time limit
        attempt = create(:test_attempt, user: user, test: theoretical_test, started_at: nil)
        expect(attempt.time_remaining).to eq(theoretical_test.time_limit_minutes * 60)

        # Started 10 minutes ago - should have 50 minutes remaining (60 - 10 = 50)
        start_time = frozen_time - 10.minutes
        attempt.update!(started_at: start_time)
        expect(attempt.time_remaining).to eq(50.minutes.to_i) # 3000 seconds

        # Completed - should return 0
        attempt.complete!
        expect(attempt.time_remaining).to eq(0)
      end
    end

    it 'computes time_elapsed correctly' do
      # Freeze time to test exact values
      frozen_time = Time.zone.parse('2024-01-01 12:00:00')
      travel_to frozen_time do
        start_time = frozen_time - 5.minutes
        attempt = create(:test_attempt, user: user, test: theoretical_test, started_at: start_time)

        # For in-progress attempts, time_elapsed should be exactly 5 minutes (300 seconds)
        expect(attempt.time_elapsed).to eq(300)

        # For completed attempts, we can test exact time difference
        completed_time = start_time + 3.minutes
        attempt.update!(completed_at: completed_time)
        expect(attempt.time_elapsed).to eq(180) # exactly 3 minutes = 180 seconds
      end
    end
  end

  describe 'timers and state helpers' do
    it 'not_started? is true when no started_at and not completed' do
      attempt = create(:test_attempt, user: user, test: theoretical_test, started_at: nil, completed_at: nil)
      expect(attempt.not_started?).to be(true)

      attempt.update!(started_at: Time.current)
      expect(attempt.not_started?).to be(false)

      attempt.update!(completed_at: Time.current)
      expect(attempt.not_started?).to be(false)
    end

    it 'time_warning? is true when <= 5 minutes remaining and > 0' do
      travel_to Time.zone.parse('2024-01-01 12:00:00') do
        attempt = create(:test_attempt, user: user, test: theoretical_test, started_at: Time.current - 56.minutes)
        expect(attempt.time_remaining).to eq(4.minutes.to_i)
        expect(attempt.time_warning?).to be(true)

        # More than 5 minutes remaining -> false
        attempt.update!(started_at: Time.current - 50.minutes)
        expect(attempt.time_warning?).to be(false)
      end
    end

    it 'time_expired? becomes true when no time remaining' do
      travel_to Time.zone.parse('2024-01-01 12:00:00') do
        attempt = create(:test_attempt, user: user, test: theoretical_test, started_at: Time.current - 61.minutes)
        expect(attempt.time_expired?).to be(true)

        # Completed attempts are considered expired for timing
        attempt = create(:test_attempt, user: user, test: theoretical_test, started_at: Time.current - 10.minutes)
        attempt.complete!
        expect(attempt.time_expired?).to be(true)
      end
    end

    it 'can_continue? is true only when in progress and not expired' do
      travel_to Time.zone.parse('2024-01-01 12:00:00') do
        attempt = create(:test_attempt, user: user, test: theoretical_test, started_at: Time.current - 10.minutes)
        expect(attempt.can_continue?).to be(true)

        attempt.update!(started_at: Time.current - 61.minutes)
        expect(attempt.can_continue?).to be(false)

        attempt.update!(completed_at: Time.current)
        expect(attempt.can_continue?).to be(false)
      end
    end

    it 'failed? is true only when completed and not passed' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      expect(attempt.failed?).to be(false)

      attempt.update!(completed_at: Time.current, passed: false)
      expect(attempt.failed?).to be(true)

      attempt.update!(passed: true)
      expect(attempt.failed?).to be(false)
    end
  end

  describe 'question collection helpers' do
    it 'answered_questions, unanswered_questions, marked_for_later return correct sets' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      q1 = create(:question, test_category: test_category)
      q2 = create(:question, test_category: test_category)
      q3 = create(:question, test_category: test_category)

      a1 = create(:answer, question: q1, correct: true)
      create(:question_response, test_attempt: attempt, question: q1, selected_answer_ids: [a1.id])
      create(:question_response, test_attempt: attempt, question: q2, selected_answer_ids: [], marked_for_later: true)
      create(:question_response, test_attempt: attempt, question: q3, selected_answer_ids: [])

      expect(attempt.answered_questions).to match_array([q1])
      expect(attempt.marked_for_later).to match_array([q2])
      expect(attempt.unanswered_questions).to match_array([q2, q3])
    end
  end

  describe 'progress_percentage' do
    it 'computes percentage based on answered theoretical questions' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      q2 = create(:question, test_category: test_category)
      a2 = create(:answer, question: q2, correct: true)
      create(:question_response, test_attempt: attempt, question: q2, selected_answer_ids: [a2.id])

      expect(attempt.answered_questions).to match_array([q2])
      expect(attempt.progress_percentage).to eq(50.0)
    end

    it 'computes percentage based on completed practical tasks' do
      attempt = create(:test_attempt, user: user, test: practical_test)
      t1 = create(:practical_task, test: practical_test)
      t2 = create(:practical_task, test: practical_test)

      expect(practical_test.practical_tasks.active.count).to eq(2)
      expect(attempt.progress_percentage).to eq(0)

      create(:practical_task_result, test_attempt: attempt, practical_task: t1, status: 'passed')
      expect(attempt.progress_percentage).to eq(50.0)

      create(:practical_task_result, test_attempt: attempt, practical_task: t2, status: 'passed')
      expect(attempt.progress_percentage).to eq(100.0)
    end
  end

  describe 'incompleted_tasks' do
    it 'returns active practical tasks not yet completed' do
      attempt = create(:test_attempt, user: user, test: practical_test)
      t1 = create(:practical_task, test: practical_test)
      t2 = create(:practical_task, test: practical_test)

      # Initially none completed
      expect(attempt.completed_tasks).to be_empty
      expect(attempt.incompleted_tasks).to match_array([t1, t2])

      # One completed
      create(:practical_task_result, test_attempt: attempt, practical_task: t1, status: 'passed')
      expect(attempt.completed_tasks).to match_array([t1])
      expect(attempt.incompleted_tasks).to match_array([t2])

      # Both completed
      create(:practical_task_result, test_attempt: attempt, practical_task: t2, status: 'passed')
      expect(attempt.completed_tasks).to match_array([t1, t2])
      expect(attempt.incompleted_tasks).to be_empty
    end
  end

  describe 'all_tasks_completed?' do
    it 'returns false when counts differ or any result not passed' do
      attempt = create(:test_attempt, user: user, test: practical_test)
      t1 = create(:practical_task, test: practical_test)
      t2 = create(:practical_task, test: practical_test)

      # No results yet: counts differ
      expect(attempt.all_tasks_completed?).to be(false)

      # One result passed, counts still differ
      create(:practical_task_result, test_attempt: attempt, practical_task: t1, status: 'passed')
      expect(attempt.all_tasks_completed?).to be(false)

      # Add second result but failed -> not all passed
      create(:practical_task_result, test_attempt: attempt, practical_task: t2, status: 'failed')
      expect(attempt.all_tasks_completed?).to be(false)

      # When both passed -> true
      attempt.practical_task_results.update_all(status: 'passed')
      expect(attempt.all_tasks_completed?).to be(true)
    end
  end

  describe 'merge_vars!' do
    it 'merges and stringifies keys, overriding existing keys' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      attempt.update!(vars: { 'foo' => 'bar', 'num' => 1 })

      attempt.merge_vars!({ foo: 'baz', added: 'yes' })
      attempt.reload

      expect(attempt.vars).to include('foo' => 'baz', 'num' => 1, 'added' => 'yes')
      # ensure keys are strings
      expect(attempt.vars.keys).to all(be_a(String))
    end
  end

  describe 'details retention' do
    it 'details_expired? is true for completed attempts older than 30 days' do
      old_completed = create(:test_attempt, user: user, test: theoretical_test, started_at: 40.days.ago, completed_at: 35.days.ago)
      recent_completed = create(:test_attempt, user: user, test: theoretical_test, started_at: 2.days.ago, completed_at: 1.day.ago)

      expect(old_completed.details_expired?).to be(true)
      expect(recent_completed.details_expired?).to be(false)
    end

    it 'purge_old_details! purges details for attempts older than 30 days' do
      old_completed = create(:test_attempt, user: user, test: theoretical_test, started_at: 40.days.ago, completed_at: 35.days.ago)
      recent_completed = create(:test_attempt, user: user, test: theoretical_test, started_at: 2.days.ago, completed_at: 1.day.ago)

      create(:question_response, test_attempt: old_completed, selected_answer_ids: [1])
      create(:question_response, test_attempt: recent_completed, selected_answer_ids: [1])

      expect {
        described_class.purge_old_details!
      }.to change { old_completed.reload.question_responses.count }.from(1).to(0)

      expect(recent_completed.reload.question_responses.count).to eq(1)
    end
  end

  describe 'score_percentage theoretical path' do
    it 'returns 0 if no question_responses and computes correct % otherwise' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      expect(attempt.score_percentage).to eq(0)

      q1 = create(:question, test_category: test_category)
      q2 = create(:question, test_category: test_category)
      a1 = create(:answer, question: q1, correct: true)
      a2 = create(:answer, question: q2, correct: false)

      create(:question_response, test_attempt: attempt, question: q1, selected_answer_ids: [a1.id])
      create(:question_response, test_attempt: attempt, question: q2, selected_answer_ids: [a2.id])

      # 1 of 2 correct -> 50%
      expect(attempt.score_percentage).to eq(50)
    end
  end
  describe 'question progress helpers' do
    it 'answers tracking and all_questions_answered?' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      q1 = create(:question, test_category: test_category, display_order: 1)
      q2 = create(:question, test_category: test_category, display_order: 2)

      # Pre-create responses placeholders
      create(:question_response, test_attempt: attempt, question: q1, selected_answer_ids: [1])
      qr2 = create(:question_response, test_attempt: attempt, question: q2, selected_answer_ids: [])

      expect(attempt.all_questions_answered?).to be(false)

      qr2.update!(selected_answer_ids: [2])
      attempt.reload

      expect(attempt.all_questions_answered?).to be(true)
    end
  end

  describe 'practical scoring' do
    it 'computes score_percentage from practical task results and score_passed? logic' do
      attempt = create(:test_attempt, user: user, test: practical_test)
      create(:practical_task, test: practical_test)
      create(:practical_task, test: practical_test)

      # No results yet -> 0
      expect(attempt.score_percentage).to eq(0)
      expect(attempt.score_passed?).to be(false)

      # Two results: one passed, one failed -> 50%
      tasks = practical_test.practical_tasks
      create(:practical_task_result, test_attempt: attempt, practical_task: tasks.first, status: 'passed')
      create(:practical_task_result, test_attempt: attempt, practical_task: tasks.second, status: 'failed')

      expect(attempt.score_percentage).to eq(50)
      expect(attempt.score_passed?).to be(false)

      # Both passed -> 100% and meets practical required 100%
      attempt.practical_task_results.update_all(status: 'passed')
      expect(attempt.score_percentage).to eq(100)
      expect(attempt.score_passed?).to be(true)
    end
  end

  describe 'initialize_question_set!' do
    it 'creates placeholder responses for active questions per category limit' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      cat1 = create(:test_category, questions_per_category: 2)
      cat2 = create(:test_category, questions_per_category: 1)

      create(:question, test_category: cat1, display_order: 1)
      create(:question, test_category: cat1, display_order: 2)
      create(:question, test_category: cat1, display_order: 3)

      create(:question, test_category: cat2, display_order: 1)
      create(:question, test_category: cat2, display_order: 2)

      theoretical_test.test_categories << [cat1, cat2]

      expect {
        attempt.initialize_question_set!
      }.to(change { attempt.question_responses.count })

      # Should not duplicate on second call
      expect {
        attempt.initialize_question_set!
      }.not_to(change { attempt.question_responses.count })

      # Selected responses count should match per-category limits (<= available questions)
      total_limit = test_category.questions_per_category + cat2.questions_per_category
      expect(attempt.question_responses.count).to be <= total_limit
    end
  end

  describe 'details cleanup' do
    it 'purge_details! removes detailed responses and score' do
      attempt = create(:test_attempt, :completed, user: user, test: theoretical_test, passed: true)
      create(:question_response, test_attempt: attempt, selected_answer_ids: [1])
      expect(attempt.question_responses.count).to eq(1)

      attempt.update!(score_percentage: 80)
      attempt.purge_details!

      expect(attempt.question_responses.count).to eq(0)
    end
  end
end
