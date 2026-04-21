class Admin::DashboardController < Admin::BaseController
  def index
    @recent_activity = TestAttempt.includes(:user, :test).order(created_at: :desc).limit(10)
    expire_date_range = Time.zone.today..ENV.fetch('ACCR_EXPIRY_NOTIFICATION_DAYS', '14').to_i.days.from_now
    @expiring_accreditations = User.joins(:test_attempts).where(test_attempts: { passed: true })
                                   .where(accreditation_expire_date: expire_date_range)
                                   .distinct.limit(10)
  end
end
