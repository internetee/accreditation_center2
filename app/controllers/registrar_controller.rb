class RegistrarController < ApplicationController
  before_action :ensure_regular_user!

  def show
    @registrar = current_user.registrar
    return handle_missing_registrar if @registrar.blank?

    @registrar_users = @registrar.users
                                 .not_admin
                                 .includes(test_attempts: :test)
                                 .order(:name, :email)
    @latest_result_by_user_id = build_latest_result_projection(@registrar_users)
  end

  private

  def handle_missing_registrar
    @registrar_users = User.none
    @latest_result_by_user_id = {}
  end

  def build_latest_result_projection(users)
    users.index_with do |user|
      latest_attempt = latest_attempt_for(user)

      {
        latest_attempt: latest_attempt,
        status: attempt_status(latest_attempt),
        result: attempt_result(latest_attempt),
        completed_at: latest_attempt&.completed_at
      }
    end
  end

  def latest_attempt_for(user)
    attempts = user.test_attempts.to_a
    return nil if attempts.empty?

    finished = attempts.select { |attempt| attempt.completed? || time_expired_only?(attempt) }
    if finished.any?
      return finished.max_by { |attempt| attempt.completed_at || attempt.started_at || attempt.created_at }
    end

    active = attempts.select { |attempt| attempt.in_progress? && !attempt.time_expired? }
    return active.max_by { |attempt| attempt.started_at || attempt.created_at } if active.any?

    nil
  end

  def time_expired_only?(attempt)
    !attempt.completed? && attempt.time_expired?
  end

  def attempt_status(attempt)
    return :not_started unless attempt
    return :passed if attempt.passed?
    return :failed if attempt.failed?
    return :time_expired if time_expired_only?(attempt)
    return :in_progress if attempt.in_progress?

    :not_started
  end

  def attempt_result(attempt)
    attempt_status(attempt)
  end
end
