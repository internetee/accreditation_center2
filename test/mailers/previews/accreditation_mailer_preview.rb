require 'ostruct'

class AccreditationMailerPreview < ActionMailer::Preview
  def accreditation_granted
    AccreditationMailer.accreditation_granted_or_reaccredited(sample_registrar, reaccreditation: false)
  end

  def reaccreditation_granted
    AccreditationMailer.accreditation_granted_or_reaccredited(sample_registrar, reaccreditation: true)
  end

  def expiry_30_days
    AccreditationMailer.expiry_30_days(sample_registrar(expiry_date: Date.current + 30.days))
  end

  def expiry_or_passed
    AccreditationMailer.expiry_or_passed(sample_registrar(expiry_date: Date.current - 1.day))
  end

  def practical_passed_not_accredited
    AccreditationMailer.practical_passed_not_accredited(sample_registrar, OpenStruct.new(id: 1))
  end

  def theoretical_passed_not_accredited
    AccreditationMailer.theoretical_passed_not_accredited(sample_registrar, OpenStruct.new(id: 1))
  end

  def admin_accreditation_window_notice
    AccreditationMailer.admin_accreditation_window_notice(sample_registrar)
  end

  def assignment_failed
    AccreditationMailer.assignment_failed(sample_user, sample_failures)
  end

  private

  def sample_registrar(expiry_date: Date.new(2028, 4, 10))
    Registrar.new(
      name: 'Preview Registrar',
      email: 'registrar@example.test',
      accreditation_date: Date.new(2026, 4, 10),
      accreditation_expire_date: expiry_date
    )
  end

  def sample_user
    User.new(
      username: 'preview_user',
      email: 'preview.user@example.test'
    )
  end

  def sample_failures
    [
      Attempts::AutoAssign::Failure.new(test_type: 'theoretical', error_message: 'No tests available'),
      Attempts::AutoAssign::Failure.new(test_type: 'practical', error_message: 'Provisioning failed')
    ]
  end
end
