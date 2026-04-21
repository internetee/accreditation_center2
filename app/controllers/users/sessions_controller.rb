# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # POST /resource/sign_in
  def create
    username, password = user_credentials
    return handle_invalid_credentials unless credentials_present?(username, password)

    user = User.find_by(username: username)

    if local_admin?(user, password)
      sign_in(user)
      redirect_after_sign_in(user)
    else
      api_authenticate_user(username, password)
    end
  end

  # DELETE /resource/sign_out
  def destroy
    session[:auth_token] = nil
    super
  end

  private

  def user_credentials
    [params.dig(:user, :username), params.dig(:user, :password)]
  end

  def credentials_present?(username, password)
    username.present? && password.present?
  end

  def handle_invalid_credentials
    flash[:alert] = t('devise.failure.invalid', authentication_keys: 'username')
    redirect_to new_user_session_path
  end

  def local_admin?(user, password)
    user&.valid_password?(password) && user.admin?
  end

  def api_authenticate_user(username, password)
    response = AuthenticationService.new(username: username, password: password).authenticate_user
    return handle_failed_auth(response) unless response[:success]

    user = find_or_create_api_user(response, password)
    sign_in(user)
    session[:auth_token] = ApiTokenService.new(username: username, password: password).generate
    assign_test_attempts(user) if ENV['AUTO_ASSIGN_TEST_ATTEMPTS'].to_s == 'true'
    redirect_after_sign_in(user)
  end

  def handle_failed_auth(response)
    flash[:alert] = response[:message]
    redirect_to new_user_session_path
  end

  def find_or_create_api_user(response, password)
    User.find_or_initialize_by(username: response[:username]).tap do |user|
      next unless user.new_record?

      user.email = response[:registrar_email]
      user.registrar_name = response[:registrar_name]
      user.accreditation_date = response[:accreditation_date]
      user.accreditation_expire_date = response[:accreditation_expire_date]
      user.role = 'user'
      user.password = password
      user.save!
    end
  end

  def redirect_after_sign_in(user)
    if user.admin?
      redirect_to admin_dashboard_path, notice: t('devise.sessions.signed_in')
    else
      redirect_to root_path, notice: t('devise.sessions.signed_in')
    end
  end

  def assign_test_attempts(user)
    failures = Attempts::AutoAssign.new(user: user).call
    return if failures.empty?

    flash[:alert] = t('users.sessions.assignment_failed')
    notify_assignment_failures(user, failures)
  end

  def notify_assignment_failures(user, failures)
    AccreditationMailer.assignment_failed(user, failures).deliver_now
  rescue StandardError => e
    Rails.logger.error("Automatic test assignment notification failed for #{user.username}: #{e.message}")
  end
end
