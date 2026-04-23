require 'rails_helper'

RSpec.describe PracticalTaskResult, type: :model do
  let(:user) { create(:user) }
  let(:test_record) { create(:test, :practical) }
  let(:attempt) { create(:test_attempt, user: user, test: test_record) }
  let(:task) { create(:practical_task, test: test_record) }
  let(:result_record) { create(:practical_task_result, test_attempt: attempt, practical_task: task, status: 'pending', result: {}) }

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

  describe '#save_running_status!' do
    it 'stores inputs and sets status to running' do
      payload = { 'domain' => 'example.ee' }

      result_record.save_running_status!(payload)

      expect(result_record.reload.status).to eq('running')
      expect(result_record.inputs).to eq(payload)
    end
  end

  describe '#persist_result!' do
    it 'sets passed status for symbol-key payload' do
      result_record.persist_result!({ passed: true, evidence: { ok: true } })

      expect(result_record.reload.status).to eq('passed')
      expect(result_record.result['evidence']).to eq('ok' => true)
    end

    it 'sets failed status for string-key payload' do
      result_record.persist_result!({ 'passed' => false, 'errors' => ['boom'] })

      expect(result_record.reload.status).to eq('failed')
      expect(result_record.result['errors']).to eq(['boom'])
    end

    it 'preserves existing admin feedback fields when result is overwritten' do
      result_record.update!(
        result: {
          'admin_feedback' => 'Looks good',
          'admin_feedback_by_name' => 'QA Admin',
          'old_key' => 'to be replaced'
        }
      )

      result_record.persist_result!({ passed: true, evidence: { checks: 2 } })
      data = result_record.reload.result

      expect(data['admin_feedback']).to eq('Looks good')
      expect(data['admin_feedback_by_name']).to eq('QA Admin')
      expect(data['evidence']).to eq('checks' => 2)
      expect(data).not_to have_key('old_key')
    end
  end

  describe 'feedback helpers' do
    it 'writes and clears feedback via #feedback=' do
      result_record.feedback = '  Useful feedback  '
      expect(result_record.result['admin_feedback']).to eq('Useful feedback')

      result_record.feedback = '   '
      expect(result_record.result).not_to have_key('admin_feedback')
    end

    it 'sets feedback author name via #set_feedback' do
      admin = create(:user, :admin, name: 'Admin Reviewer')

      result_record.set_feedback('Please retry task', admin: admin)

      expect(result_record.feedback).to eq('Please retry task')
      expect(result_record.feedback_by_name).to eq('Admin Reviewer')
    end

    it 'removes feedback author when feedback is blank' do
      admin = create(:user, :admin, name: 'Admin Reviewer')
      result_record.set_feedback('Initial', admin: admin)

      result_record.set_feedback(' ', admin: admin)

      expect(result_record.feedback).to be_nil
      expect(result_record.feedback_by_name).to be_nil
    end
  end

  describe 'validated_at synchronization' do
    it 'sets validated_at when status transitions to passed' do
      expect(result_record.validated_at).to be_nil

      result_record.update!(status: 'passed')

      expect(result_record.validated_at).to be_present
    end

    it 'clears validated_at when status transitions back to running' do
      result_record.update!(status: 'passed')
      expect(result_record.validated_at).to be_present

      result_record.update!(status: 'running')

      expect(result_record.validated_at).to be_nil
    end

    it 'preserves existing validated_at when already set and status becomes failed' do
      timestamp = 2.days.ago.change(usec: 0)
      result_record.update_columns(validated_at: timestamp, status: 'running')

      result_record.update!(status: 'failed')

      expect(result_record.reload.validated_at.to_i).to eq(timestamp.to_i)
    end
  end

  describe '.ransackable_attributes' do
    it 'includes validated_at and status' do
      attrs = described_class.ransackable_attributes
      expect(attrs).to include('status', 'validated_at')
    end
  end
end
