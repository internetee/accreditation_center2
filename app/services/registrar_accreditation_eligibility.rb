# frozen_string_literal: true

# Encapsulates registrar-level accreditation rules shared by model/service flows.
class RegistrarAccreditationEligibility
  def self.accredited?(registrar)
    new(registrar).accredited?
  end

  def self.sync_eligible?(registrar)
    new(registrar).sync_eligible?
  end

  def self.can_sync_from_theoretical?(registrar)
    new(registrar).can_sync_from_theoretical?
  end

  def initialize(registrar, triggering_attempt: nil)
    @registrar = registrar
    @triggering_attempt = triggering_attempt
  end

  # Initial accreditation in the portal: both test types passed.
  def accredited?
    return false unless @registrar

    theory_satisfied? && practical_satisfied?
  end

  # Registrar already known as accredited from REPP (imported on login or prior sync).
  def previously_accredited_in_system?
    return false unless @registrar

    @registrar.accreditation_date.present? || @registrar.accreditation_expire_date.present?
  end

  # Reaccreditation: already accredited in system + at least one passed theoretical attempt.
  def reaccreditation_eligible?
    previously_accredited_in_system? && last_theory_passed_at.present?
  end

  def sync_eligible?
    accredited? || reaccreditation_eligible?
  end

  def can_sync_from_theoretical?
    previously_accredited_in_system? || accredited?
  end

  def skip_partial_accreditation_notice?
    accredited? || previously_accredited_in_system?
  end

  def last_theory_passed_at
    return nil unless @registrar

    [theory_attempts.maximum(:completed_at), triggering_theory_completed_at].compact.max
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

  def theory_satisfied?
    theory_attempts.exists? || triggering_theory_pass?
  end

  def practical_satisfied?
    practical_attempts.exists? || triggering_practical_pass?
  end

  def triggering_theory_pass?
    triggering_pass?(:theoretical)
  end

  def triggering_practical_pass?
    triggering_pass?(:practical)
  end

  def triggering_theory_completed_at
    triggering_theory_pass? ? @triggering_attempt.completed_at : nil
  end

  def triggering_pass?(test_type)
    attempt = @triggering_attempt
    return false unless attempt&.passed? && attempt.completed_at.present? && attempt.started_at.present?

    attempt.test&.public_send("#{test_type}?")
  end
end
