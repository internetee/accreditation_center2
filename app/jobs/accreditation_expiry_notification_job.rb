class AccreditationExpiryNotificationJob < ApplicationJob
  queue_as :default
  # Do not use retry_on or other retry logic; fail immediately on job exceptions.
  discard_on StandardError do |exception|
    Rails.logger.error "Error in AccreditationExpiryNotificationJob: #{exception.message}"
  end

  def perform
    send_user_notifications
    send_coordinator_notifications
  end

  private

  def send_user_notifications
    days_before = ENV.fetch('ACCR_EXPIRY_NOTIFICATION_DAYS', '14').split(',').map(&:to_i)
    days_before.each do |days|
      notify_users_before_expiry(days)
    end

    notify_users_on_expiry_day
  end

  def send_coordinator_notifications
    expiring_users = find_expiring_users
    return if expiring_users.empty?

    AccreditationMailer.coordinator_notification(expiring_users).deliver_now
    Rails.logger.info "Sent coordinator notification for #{expiring_users.count} users with expiring or soon-to-expire accreditations"
  end

  def find_expiring_users
    days_before = ENV.fetch('COORDINATOR_ACCR_EXPIRY_NOTIFICATION_DAYS', '14').to_i
    expiring_soon_users = User.where('DATE(accreditation_expire_date) = ?', Time.zone.today + days_before)
    expired_today_users = User.where('DATE(accreditation_expire_date) = ?', Time.zone.today)

    expiring_soon_users.or(expired_today_users).distinct
  end

  def notify_users_before_expiry(days_before)
    target_date = Time.zone.today + days_before.days
    users_to_notify = User.where('DATE(accreditation_expire_date) = ?', target_date).distinct

    users_to_notify.find_each do |user|
      Rails.logger.info "Sending expiry warning to user #{user.username} for #{days_before} days before expiry"
      AccreditationMailer.expiry_warning(user, days_before.to_i).deliver_now
    end
  end

  # Notify users at the very start of the accreditation expiry day
  def notify_users_on_expiry_day
    now = Time.zone.now
    # Only send notification if it's within the first 10 minutes of the expiry day (to avoid duplicate sends if job is rerun)
    if now.to_date == (expiry_day = Time.zone.today) && now.hour.zero? && now.min < 10
      users_to_notify = User.where('DATE(accreditation_expire_date) = ?', expiry_day).distinct
      users_to_notify.find_each do |user|
        Rails.logger.info "Sending expiry notification to user #{user.username} on expiry day"
        AccreditationMailer.expiry_notification(user).deliver_now
      end
    end
  end
end
