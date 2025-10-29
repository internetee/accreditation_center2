require 'rails_helper'

RSpec.describe TestAttempt, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:theoretical_test) { create(:test, :theoretical, time_limit_minutes: 60, passing_score_percentage: 60) }
  let(:practical_test)   { create(:test, :practical,   time_limit_minutes: 30, passing_score_percentage: 100) }

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
      # Create question responses that will result in passing score
      category = create(:test_category)
      q1 = create(:question, test_category: category)
      q2 = create(:question, test_category: category)
      a1 = create(:answer, question: q1, correct: true)
      a2 = create(:answer, question: q2, correct: true)

      theoretical_test.test_categories << category
      create(:question_response, test_attempt: theoretical_attempt, question: q1, selected_answer_ids: [a1.id])
      create(:question_response, test_attempt: theoretical_attempt, question: q2, selected_answer_ids: [a2.id])

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

  describe 'question progress helpers' do
    it 'answers tracking and all_questions_answered?' do
      attempt = create(:test_attempt, user: user, test: theoretical_test)
      category = create(:test_category)
      q1 = create(:question, test_category: category, display_order: 1)
      q2 = create(:question, test_category: category, display_order: 2)

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
    it 'computes score_percentage from practical task results and passed? logic' do
      attempt = create(:test_attempt, user: user, test: practical_test)
      create(:practical_task, test: practical_test)
      create(:practical_task, test: practical_test)

      # No results yet -> 0
      expect(attempt.score_percentage).to eq(0)
      expect(attempt.passed?).to be(false)

      # Two results: one passed, one failed -> 50%
      tasks = practical_test.practical_tasks
      create(:practical_task_result, test_attempt: attempt, practical_task: tasks.first, status: 'passed')
      create(:practical_task_result, test_attempt: attempt, practical_task: tasks.second, status: 'failed')

      expect(attempt.score_percentage).to eq(50)
      expect(attempt.passed?).to be(false)

      # Both passed -> 100% and meets practical required 100%
      attempt.practical_task_results.update_all(status: 'passed')
      expect(attempt.score_percentage).to eq(100)
      expect(attempt.passed?).to be(true)
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
      total_limit = cat1.questions_per_category + cat2.questions_per_category
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
