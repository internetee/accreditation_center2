class PracticalTaskResult < ApplicationRecord
  belongs_to :test_attempt
  belongs_to :practical_task

  enum :status, { pending: 'pending', running: 'running', passed: 'passed', failed: 'failed' }

  def correct?
    status == 'passed'
  end

  def save_running_status!(inputs)
    self.inputs = inputs
    self.status = :running
    save!
  end

  def persist_result!(result)
    self.result = result
    self.status = result[:passed] ? :passed : :failed
    save!
  end
end
