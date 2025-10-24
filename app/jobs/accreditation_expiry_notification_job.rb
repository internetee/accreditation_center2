class AccreditationExpiryNotificationJob < ApplicationJob
  queue_as :default

  def perform
    send_user_notifications
    send_coordinator_notifications
  end

  private

  def send_user_notifications
    # Notify users 14 days before expiry
    notify_users_before_expiry(14.days)

    # Notify users 7 days before expiry
    notify_users_before_expiry(7.days)

    # Notify users on expiry day
    notify_users_on_expiry_day
  end

  def send_coordinator_notifications
    # Find users whose accreditations are expiring soon
    expiring_users = User.joins(:test_attempts)
                         .where(test_attempts: { passed: true })
                         .where('test_attempts.created_at < ?', accreditation_period.ago)
                         .where(role: :user)
                         .distinct

    if expiring_users.any?
      AccreditationMailer.coordinator_notification(expiring_users).deliver_now
      Rails.logger.info "Sent coordinator notification for #{expiring_users.count} users with expiring accreditations"
    end
  end

  def notify_users_before_expiry(days_before)
    users_to_notify = User.joins(:test_attempts)
                          .where(test_attempts: { passed: true })
                          .where('test_attempts.created_at < ?', (accreditation_period - days_before).ago)
                          .distinct

    users_to_notify.find_each do |user|
      AccreditationMailer.expiry_warning(user, days_before.to_i).deliver_now
    end
  end

  def notify_users_on_expiry_day
    users_to_notify = User.joins(:test_attempts)
                          .where(test_attempts: { passed: true })
                          .where('test_attempts.created_at < ?', accreditation_period.ago)
                          .distinct

    users_to_notify.find_each do |user|
      AccreditationMailer.expiry_notification(user).deliver_now
    end
  end

  def accreditation_period
    ENV.fetch('ACCR_EXPIRY_YEARS', 2).to_i.years
  end
end
