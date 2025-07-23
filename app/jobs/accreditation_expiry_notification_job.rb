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
    # Find users whose last accredited user expires today
    expiring_users = User.joins(:test_attempts)
                        .where(test_attempts: { passed: true })
                        .where('test_attempts.created_at < ?', 1.year.ago)
                        .distinct
    
    if expiring_users.any?
      # This would send notification to EIS coordinator
      # For now, just log it
      Rails.logger.info "Users with expiring accreditation: #{expiring_users.pluck(:username).join(', ')}"
    end
  end
  
  def notify_users_before_expiry(days_before)
    expiry_date = days_before.from_now.to_date
    
    users_to_notify = User.joins(:test_attempts)
                         .where(test_attempts: { passed: true })
                         .where('test_attempts.created_at < ?', (1.year - days_before).ago)
                         .distinct
    
    users_to_notify.find_each do |user|
      AccreditationMailer.expiry_warning(user, days_before.to_i).deliver_now
    end
  end
  
  def notify_users_on_expiry_day
    expiry_date = Date.current
    
    users_to_notify = User.joins(:test_attempts)
                         .where(test_attempts: { passed: true })
                         .where('test_attempts.created_at < ?', 1.year.ago)
                         .distinct
    
    users_to_notify.find_each do |user|
      AccreditationMailer.expiry_notification(user).deliver_now
    end
  end
end 