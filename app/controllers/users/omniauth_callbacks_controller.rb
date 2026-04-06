# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # GET /users/auth/oidc/callback
  def oidc
    auth = request.env['omniauth.auth']
    return redirect_auth_error(t('devise.omniauth_callbacks.failure')) if auth.blank?
    return redirect_to_existing_session if same_user_callback?(auth)
    return redirect_admin_to_password_login if admin_identity?(auth)

    sign_out(current_user) if user_signed_in?

    user = User.from_omniauth(auth)
    return redirect_auth_error(user.errors.full_messages.join(', ')) unless user&.persisted?
    return redirect_admin_to_password_login if user.admin?

    api_authenticate_user(auth)
  end

  def failure
    message = if params[:error].present? || params[:error_description].present?
                "#{params[:error]}: #{params[:error_description]}"
              else
                t('devise.omniauth_callbacks.failure')
              end
    redirect_auth_error(message)
  end

  private

  def admin_identity?(auth)
    provider = auth.provider.to_s
    uid = auth.uid.to_s
    email = auth.dig('info', 'email').to_s.downcase

    User.admin.where(provider: provider, uid: uid).exists? ||
      (email.present? && User.admin.where('LOWER(email) = ?', email).exists?)
  end

  def same_user_callback?(auth)
    user_signed_in? &&
      current_user.provider == auth.provider.to_s &&
      current_user.uid == auth.uid.to_s
  end

  def redirect_to_existing_session
    redirect_to after_sign_in_path_for(current_user), notice: t('devise.sessions.signed_in')
  end

  def api_authenticate_user(auth)
    uid = auth.uid.to_s
    return redirect_auth_error(t('errors.invalid_credentials')) if uid.blank?

    response = OidcAuthenticationService.new(uid: uid).authenticate_user
    return handle_failed_auth(response) unless response[:success]

    user = begin
      find_or_create_api_user(response, uid)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("OIDC user persistence failed uid=#{uid}: #{e.record.errors.full_messages.join(', ')}")
      return redirect_auth_error(e.record.errors.full_messages.to_sentence)
    rescue StandardError => e
      Rails.logger.error("OIDC user creation error uid=#{uid}: #{e.class} #{e.message}")
      return redirect_auth_error(t('errors.unexpected_response'))
    end
    return redirect_auth_error(t('errors.unexpected_response')) unless user&.persisted?

    sign_in(user)
    session[:auth_token] = response[:auth_token]
    assign_test_attempts(user) if ENV['AUTO_ASSIGN_TEST_ATTEMPTS'].to_s == 'true'
    redirect_to after_sign_in_path_for(user), notice: t('devise.sessions.signed_in')
  end

  def handle_failed_auth(response)
    redirect_auth_error(response[:message] || t('errors.unexpected_response'))
  end

  def find_or_create_api_user(response, uid)
    User.find_or_initialize_by(provider: 'oidc', uid: uid).tap do |user|
      user.role ||= 'user'
      user.username = response[:username]
      user.name = user.name || response[:username]
      user.email = response[:registrar_email].presence || user.email
      user.registrar_name = response[:registrar_name].presence || user.registrar_name
      user.accreditation_date = response[:accreditation_date].presence || user.accreditation_date
      user.accreditation_expire_date = response[:accreditation_expire_date].presence || user.accreditation_expire_date
      user.save!
    end
  end

  def redirect_auth_error(message)
    flash[:alert] = message
    redirect_to new_user_session_path
  end

  def redirect_admin_to_password_login
    flash[:alert] = t('errors.invalid_credentials')
    redirect_to new_admin_session_path
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
    Rails.logger.error("Automatic test assignment notification failed for #{user.name}: #{e.message}")
  end
end
