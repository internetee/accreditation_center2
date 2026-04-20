class TestsController < ApplicationController
  before_action :ensure_regular_user!
  before_action :set_resources
  before_action :ensure_test_not_expired, except: %i[start]
  before_action :block_history_during_active_attempt!, only: :question

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
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('tests.test_not_found')
  end

  def ensure_test_not_expired
    return unless @test_attempt.in_progress?
    return unless @test_attempt.time_expired?

    @test_attempt.complete!
    redirect_to send("results_#{@test.test_type.underscore}_test_path", @test, attempt: @test_attempt.access_code),
                alert: t('tests.time_expired')
  end

  # Prevent viewing history while a test attempt is in progress for the same account
  def block_history_during_active_attempt!
    other_in_progress_attempt = current_user.test_attempts.includes(:test)
                                            .in_progress.where.not(id: @test_attempt.id)
                                            .where(test: { test_type: @test.test_type })
                                            .reject(&:time_expired?)
                                            .any?

    return if !other_in_progress_attempt || @test_attempt.in_progress?

    redirect_to root_path, alert: I18n.t('tests.history_blocked_while_active')
  end
end
