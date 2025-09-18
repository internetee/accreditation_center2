class TestsController < ApplicationController
  before_action :ensure_regular_user!
  before_action :set_resources
  before_action :ensure_test_not_expired, except: %i[start]

  def start
    return if @test_attempt.in_progress?

    @test_attempt.update!(started_at: Time.current)
  end

  def question; end
  def answer; end
  def results; end

  private

  def set_resources
    @test = Test.active.friendly.find(params[:id])
    @test_attempt = current_user.test_attempts.find_by!(
      test: @test,
      access_code: params[:attempt]
    )
  end

  def ensure_test_not_expired
    return unless @test_attempt.in_progress?
    return unless @test_attempt.time_expired?

    @test_attempt.complete!
    redirect_to send("results_#{@test.test_type.underscore}_test_path", @test, attempt: @test_attempt.access_code),
                alert: t('tests.time_expired')
  end
end
