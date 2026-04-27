# frozen_string_literal: true

class RegistrarAccreditationNotificationsService
  REACCREDITATION_WINDOW_DAYS = 30

  EVENT_TYPES = {
    practical_passed_not_accredited: 'practical_passed_not_accredited',
    theoretical_passed_not_accredited: 'theoretical_passed_not_accredited',
    accreditation_granted: 'accreditation_granted',
    reaccreditation_granted: 'reaccreditation_granted',
    admin_accreditation_window_notice: 'admin_accreditation_window_notice',
    expiry_30_days: 'expiry_30_days',
    expiry_or_passed: 'expiry_or_passed'
  }.freeze

  def notify_test_completion(test_attempt)
    return unless test_attempt.is_a?(TestAttempt)
    return unless test_attempt.passed?

    registrar = test_attempt.user&.registrar
    return if registrar.blank?
    return if RegistrarAccreditationEligibility.accredited?(registrar)

    event_type = test_attempt.test.theoretical? ? EVENT_TYPES[:theoretical_passed_not_accredited] : EVENT_TYPES[:practical_passed_not_accredited]
    cycle_key = pending_cycle_key(registrar)
    return unless record_event(registrar: registrar, event_type: event_type, cycle_key: cycle_key)

    mail = if test_attempt.test.theoretical?
             AccreditationMailer.theoretical_passed_not_accredited(registrar, test_attempt)
           else
             AccreditationMailer.practical_passed_not_accredited(registrar, test_attempt)
           end
    mail.deliver_later
  end

  def notify_accreditation_sync(registrar:, previous_accreditation_date:, previous_accreditation_expire_date:)
    return unless registrar.is_a?(Registrar)
    return if registrar.accreditation_date.blank?

    if previous_accreditation_date.blank?
      send_accreditation_granted(registrar)
      return
    end

    return if previous_accreditation_expire_date.blank?
    return unless reaccredited_within_window?(registrar, previous_accreditation_expire_date)

    send_reaccreditation_granted(registrar, previous_accreditation_expire_date)
    send_admin_window_notice(registrar, previous_accreditation_expire_date)
  end

  def notify_daily_expiry_checks(reference_date: Time.zone.today)
    window_start = reference_date.to_date + REACCREDITATION_WINDOW_DAYS.days

    Registrar.where.not(accreditation_expire_date: nil).find_each do |registrar|
      expires_on = registrar.accreditation_expire_date.to_date

      if expires_on == window_start
        send_expiry_30_days(registrar, expires_on)
      elsif expires_on <= reference_date.to_date
        send_expiry_or_passed(registrar, expires_on)
      end
    end
  end

  private

  def send_expiry_30_days(registrar, expires_on)
    return unless AccreditationMailer.respond_to?(:expiry_30_days)
    return unless record_event(registrar: registrar, event_type: EVENT_TYPES[:expiry_30_days], cycle_key: expires_on.iso8601)

    AccreditationMailer.expiry_30_days(registrar).deliver_later
  end

  def send_expiry_or_passed(registrar, expires_on)
    return unless AccreditationMailer.respond_to?(:expiry_or_passed)
    return unless record_event(registrar: registrar, event_type: EVENT_TYPES[:expiry_or_passed], cycle_key: expires_on.iso8601)

    AccreditationMailer.expiry_or_passed(registrar).deliver_later
  end

  def send_accreditation_granted(registrar)
    cycle_key = accreditation_cycle_key(registrar)
    return unless record_event(registrar: registrar, event_type: EVENT_TYPES[:accreditation_granted], cycle_key: cycle_key)

    AccreditationMailer.accreditation_granted_or_reaccredited(registrar, reaccreditation: false).deliver_later
  end

  def send_reaccreditation_granted(registrar, previous_expire_date)
    cycle_key = reaccreditation_cycle_key(previous_expire_date)
    return unless record_event(registrar: registrar, event_type: EVENT_TYPES[:reaccreditation_granted], cycle_key: cycle_key)

    AccreditationMailer.accreditation_granted_or_reaccredited(registrar, reaccreditation: true).deliver_later
  end

  def send_admin_window_notice(registrar, previous_expire_date)
    cycle_key = reaccreditation_cycle_key(previous_expire_date)
    return unless record_event(registrar: registrar, event_type: EVENT_TYPES[:admin_accreditation_window_notice], cycle_key: cycle_key)

    AccreditationMailer.admin_accreditation_window_notice(registrar).deliver_later
  end

  def reaccredited_within_window?(registrar, previous_expire_date)
    renewed_on = registrar.accreditation_date.to_date
    expires_on = previous_expire_date.to_date

    renewed_on.between?(expires_on - REACCREDITATION_WINDOW_DAYS.days, expires_on)
  end

  def accreditation_cycle_key(registrar)
    registrar.accreditation_expire_date&.to_date&.iso8601 || registrar.accreditation_date.to_date.iso8601
  end

  def reaccreditation_cycle_key(previous_expire_date)
    previous_expire_date.to_date.iso8601
  end

  def pending_cycle_key(registrar)
    registrar.accreditation_expire_date&.to_date&.iso8601 || 'pending_accreditation'
  end

  def record_event(registrar:, event_type:, cycle_key:)
    RegistrarNotificationEvent.create!(
      registrar: registrar,
      event_type: event_type,
      cycle_key: cycle_key,
      sent_at: Time.current
    )
    true
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    false
  end
end
