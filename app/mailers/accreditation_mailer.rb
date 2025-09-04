class AccreditationMailer < ApplicationMailer
  def expiry_warning(user, days_before)
    @user = user
    @days_before = days_before
    @expiry_date = user.test_attempts.where(passed: true).order(:created_at).last.created_at + 1.year

    mail(
      to: user.email,
      subject: t('mailers.accreditation.expiry_warning.subject', days: days_before)
    )
  end

  def expiry_notification(user)
    @user = user
    @expiry_date = user.test_attempts.where(passed: true).order(:created_at).last.created_at + 1.year

    mail(
      to: user.email,
      subject: t('mailers.accreditation.expiry_notification.subject')
    )
  end

  def test_completion(user, test_attempt)
    @user = user
    @test_attempt = test_attempt
    @test = test_attempt.test

    mail(
      to: user.email,
      subject: t('mailers.accreditation.test_completion.subject', test: @test.title)
    )
  end

  def coordinator_notification(expiring_users)
    @expiring_users = expiring_users

    mail(
      to: Rails.application.credentials.coordinator_email,
      subject: t('mailers.accreditation.coordinator_notification.subject')
    )
  end
end
