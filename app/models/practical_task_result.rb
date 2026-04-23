class PracticalTaskResult < ApplicationRecord
  belongs_to :test_attempt
  belongs_to :practical_task

  enum :status, { pending: 'pending', running: 'running', passed: 'passed', failed: 'failed' }
  before_validation :sync_validated_at_with_status, if: :will_save_change_to_status?

  def correct?
    status == 'passed'
  end

  def save_running_status!(inputs)
    self.inputs = inputs
    self.status = :running
    save!
  end

  def persist_result!(result)
    previous_feedback_data = self.result.to_h.slice(
      'admin_feedback',
      'admin_feedback_by_name'
    )
    self.result = result
    self.result = self.result.to_h.merge(previous_feedback_data) if previous_feedback_data.present?

    passed = self.result.to_h.with_indifferent_access[:passed]
    self.status = passed ? :passed : :failed
    save!
  end

  def feedback
    result.to_h['admin_feedback']
  end

  def feedback=(value)
    raw_result = result.to_h.deep_dup
    text = value.to_s.strip

    if text.present?
      raw_result['admin_feedback'] = text
    else
      raw_result.delete('admin_feedback')
    end

    self.result = raw_result
  end

  def set_feedback(value, admin:)
    self.feedback = value

    raw_result = result.to_h.deep_dup
    if raw_result['admin_feedback'].present?
      raw_result['admin_feedback_by_name'] = admin_display_name(admin)
    else
      raw_result.delete('admin_feedback_by_name')
    end

    self.result = raw_result
  end

  def feedback_by_name
    result.to_h['admin_feedback_by_name']
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[status created_at updated_at validated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[test_attempt practical_task]
  end

  private

  def sync_validated_at_with_status
    self.validated_at =
      if passed? || failed?
        validated_at || Time.current
      else
        nil
      end
  end

  def admin_display_name(admin)
    return if admin.blank?

    admin.try(:display_name).presence || admin.try(:name).presence || admin.try(:email)
  end
end
