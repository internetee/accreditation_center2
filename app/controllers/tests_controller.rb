class TestsController < ApplicationController
  COMPLETED_ATTEMPT_REVIEW_WINDOW = 10.minutes
  REVIEW_ACCESS_SESSION_KEY = :completed_attempt_review_access

  before_action :ensure_regular_user!
  before_action :find_resources
  before_action :ensure_test_not_expired, except: %i[start]
  before_action :block_history_during_active_attempt!, only: :question
  before_action :ensure_completed_attempt_review_access!, only: %i[question answer]

  helper_method :can_review_completed_attempt?

  def start
    return if @test_attempt.in_progress?

    @test_attempt.update!(started_at: Time.current)
  end

  def question; end
  def answer; end
  def results; end

  private

  def find_resources
    @test_attempt = current_user.test_attempts.includes(:test).find_by!(
      access_code: params[:attempt]
    )
    @test = @test_attempt.test
    requested_test_id = params[:id].to_s
    matches_requested_test = (@test.to_param == requested_test_id) || (@test.id.to_s == requested_test_id)
    raise ActiveRecord::RecordNotFound unless matches_requested_test
    # If admin deactivates a test mid-session, allow already-started/completed attempts to continue/view.
    return if @test.active? || @test_attempt.started_at.present? || @test_attempt.completed_at.present?

    raise ActiveRecord::RecordNotFound
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('tests.test_not_found')
  end

  def ensure_test_not_expired
    return unless @test_attempt.in_progress?
    return unless @test_attempt.time_expired?

    @test_attempt.complete!
    grant_completed_attempt_review_access!
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

  def ensure_completed_attempt_review_access!
    return unless @test_attempt.completed?
    return if can_review_completed_attempt?

    redirect_to send("results_#{@test.test_type.underscore}_test_path", @test, attempt: @test_attempt.access_code),
                alert: t('tests.review_access_expired')
  end

  def can_review_completed_attempt?
    return false unless @test_attempt&.completed?
    return false unless @test_attempt.completed_at >= COMPLETED_ATTEMPT_REVIEW_WINDOW.ago

    review_granted_at = completed_attempt_review_access[@test_attempt.access_code]
    return false if review_granted_at.blank?

    Time.zone.at(review_granted_at.to_i) >= COMPLETED_ATTEMPT_REVIEW_WINDOW.ago
  end

  def grant_completed_attempt_review_access!
    return unless @test_attempt.completed?

    session[REVIEW_ACCESS_SESSION_KEY] = completed_attempt_review_access
      .merge(@test_attempt.access_code => Time.current.to_i)
      .select { |_access_code, granted_at| granted_at.to_i >= COMPLETED_ATTEMPT_REVIEW_WINDOW.ago.to_i }
  end

  def completed_attempt_review_access
    raw = session[REVIEW_ACCESS_SESSION_KEY]
    raw.is_a?(Hash) ? raw : {}
  end
end
