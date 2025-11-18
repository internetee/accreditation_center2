class HomeController < ApplicationController
  before_action :ensure_regular_user!

  def index
    load_test_attempts
    load_accreditation_info
  end

  private

  def load_test_attempts
    scope = current_user.test_attempts.includes(:test).order(created_at: :desc)
    @assigned_tests = scope.not_completed
    @completed_tests = scope.completed.limit(5)
    @test_statistics = current_user.test_statistics
  end

  def load_accreditation_info
    @accreditation_expiry_date = current_user.accreditation_expire_date
    @accreditation_expires_soon = current_user.accreditation_expires_soon?
    @days_until_expiry = current_user.days_until_accreditation_expiry
  end
end
