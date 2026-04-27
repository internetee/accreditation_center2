# frozen_string_literal: true

# Encapsulates registrar-level accreditation rules shared by model/service flows.
class RegistrarAccreditationEligibility
  def self.accredited?(registrar)
    new(registrar).accredited?
  end

  def initialize(registrar)
    @registrar = registrar
  end

  def accredited?
    return false unless @registrar

    theory_attempts.exists? && practical_attempts.exists?
  end

  def last_theory_passed_at
    return nil unless @registrar

    theory_attempts.maximum(:completed_at)
  end

  private

  def attempts
    @attempts ||= @registrar.test_attempts.passed.completed.joins(:test)
  end

  def theory_attempts
    attempts.where(tests: { test_type: :theoretical })
  end

  def practical_attempts
    attempts.where(tests: { test_type: :practical })
  end
end
