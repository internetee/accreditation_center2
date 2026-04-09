# frozen_string_literal: true

# Encapsulates registrar-level accreditation rules shared by model/service flows.
class RegistrarAccreditationEligibility
  def self.accredited?(registrar_name)
    new(registrar_name).accredited?
  end

  def initialize(registrar_name)
    @registrar_name = registrar_name.to_s.strip
  end

  def accredited?
    return false if @registrar_name.blank?

    theory_passed? && practical_passed?
  end

  def last_theory_passed_at
    return nil if @registrar_name.blank?

    theory_attempts.maximum(:completed_at)
  end

  private

  def attempts
    @attempts ||= TestAttempt.passed.completed
                             .joins(:user, :test)
                             .where(users: { registrar_name: @registrar_name })
  end

  def theory_passed?
    theory_attempts.exists?
  end

  def practical_passed?
    attempts.where(tests: { test_type: :practical }).exists?
  end

  def theory_attempts
    attempts.where(tests: { test_type: :theoretical })
  end
end
