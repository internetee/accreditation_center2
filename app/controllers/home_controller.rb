class HomeController < ApplicationController
  before_action :ensure_regular_user!

  def index
    @assigned_tests = current_user.test_attempts.not_completed.includes(:test).order(created_at: :desc)
    @completed_tests = current_user.test_attempts.completed.includes(:test).order(created_at: :desc).limit(5)
    @test_statistics = current_user.test_statistics
    @accreditation_expiry_date = current_user.accreditation_expire_date
    @accreditation_expires_soon = current_user.accreditation_expires_soon?
    @days_until_expiry = current_user.days_until_accreditation_expiry
  end
end
