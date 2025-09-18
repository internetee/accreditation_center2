class PracticalTaskResult < ApplicationRecord
  belongs_to :test_attempt
  belongs_to :practical_task

  enum :status, { pending: 'pending', running: 'running', passed: 'passed', failed: 'failed' }
end
