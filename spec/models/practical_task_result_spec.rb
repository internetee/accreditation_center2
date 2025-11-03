require 'rails_helper'

RSpec.describe PracticalTaskResult, type: :model do
  let(:user) { create(:user) }
  let(:test_record) { create(:test, :practical) }
  let(:attempt) { create(:test_attempt, user: user, test: test_record) }
  let(:task) { create(:practical_task, test: test_record) }

  describe 'associations' do
    it 'belongs to test_attempt' do
      result = create(:practical_task_result, test_attempt: attempt, practical_task: task)
      expect(result.test_attempt).to eq(attempt)
      expect(attempt.practical_task_results).to include(result)
    end

    it 'belongs to practical_task' do
      result = create(:practical_task_result, test_attempt: attempt, practical_task: task)
      expect(result.practical_task).to eq(task)
      expect(task.practical_task_results).to include(result) if task.respond_to?(:practical_task_results)
    end
  end

  describe 'enums' do
    it 'defines status enum with expected values' do
      result = create(:practical_task_result, test_attempt: attempt, practical_task: task, status: 'pending')
      expect(result.status).to eq('pending')

      result.running!
      expect(result.status).to eq('running')

      result.passed!
      expect(result.status).to eq('passed')

      result.failed!
      expect(result.status).to eq('failed')
    end
  end

  describe '#correct?' do
    it 'returns true only when status is passed' do
      task2 = create(:practical_task, test: test_record)
      r1 = create(:practical_task_result, test_attempt: attempt, practical_task: task, status: 'passed')
      r2 = create(:practical_task_result, test_attempt: attempt, practical_task: task2, status: 'failed')

      expect(r1.correct?).to be(true)
      expect(r2.correct?).to be(false)
    end
  end
end
