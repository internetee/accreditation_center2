class Admin::DashboardController < Admin::BaseController
  def index
    @recent_activity = TestAttempt.includes(:user, :test).order(created_at: :desc).limit(5)
    @expiring_accreditations = User.joins(:test_attempts).where(test_attempts: { passed: true })
                                   .where('test_attempts.created_at < ?', 11.months.ago)
                                   .distinct.limit(5)
  end
end
