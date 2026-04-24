class HomeController < ApplicationController
  before_action :ensure_regular_user!

  def index
    @registrar = current_user.registrar
    load_test_attempts
  end

  private

  def load_test_attempts
    scope = current_user.test_attempts.includes(:test).order(created_at: :desc)
    @assigned_tests = scope.not_completed.reject(&:time_expired?)
    @completed_tests = scope.completed.limit(5)
    @test_statistics = current_user.test_statistics
  end
end
