class AccreditationMailer < ApplicationMailer
  def test_completion(user, test_attempt)
    @user = user
    @test_attempt = test_attempt
    @test = test_attempt.test

    mail(
      to: user.email,
      subject: t('mailers.accreditation.test_completion.subject', test: @test.title)
    )
  end

  def accreditation_granted_or_reaccredited(registrar, reaccreditation: false)
    @registrar = registrar
    @reaccreditation = reaccreditation

    subject_key = reaccreditation ? 'mailers.accreditation.reaccreditation_granted.subject' : 'mailers.accreditation.accreditation_granted.subject'

    mail(
      to: registrar.email,
      subject: I18n.t(subject_key, registrar: registrar.name)
    )
  end

  def expiry_30_days(registrar)
    @registrar = registrar

    mail(
      to: registrar.email,
      subject: I18n.t('mailers.accreditation.expiry_30_days.subject', registrar: registrar.name, expiry_date: localized_expiry_date(registrar))
    )
  end

  def expiry_or_passed(registrar)
    @registrar = registrar

    mail(
      to: registrar.email,
      subject: I18n.t('mailers.accreditation.expiry_or_passed.subject', registrar: registrar.name)
    )
  end

  def practical_passed_not_accredited(registrar, test_attempt)
    @registrar = registrar
    @test_attempt = test_attempt

    mail(
      to: registrar.email,
      subject: I18n.t('mailers.accreditation.practical_passed_not_accredited.subject', registrar: registrar.name)
    )
  end

  def theoretical_passed_not_accredited(registrar, test_attempt)
    @registrar = registrar
    @test_attempt = test_attempt

    mail(
      to: registrar.email,
      subject: I18n.t('mailers.accreditation.theoretical_passed_not_accredited.subject', registrar: registrar.name)
    )
  end

  def admin_accreditation_window_notice(registrar)
    @registrar = registrar

    mail(
      to: User.admin.pluck(:email),
      subject: I18n.t('mailers.accreditation.admin_accreditation_window_notice.subject', registrar: registrar.name)
    )
  end

  def assignment_failed(user, failures)
    @user = user
    @failures = failures

    mail(
      to: User.admin.pluck(:email),
      subject: t('mailers.accreditation.assignment_failed.subject', name: user.display_name)
    )
  end

  private

  def localized_expiry_date(registrar)
    return '' if registrar.accreditation_expire_date.blank?

    I18n.l(registrar.accreditation_expire_date.to_date, format: :default)
  end
end
