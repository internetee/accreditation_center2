# app/controllers/concerns/registry_token_guard.rb
module RegistryTokenGuard
  extend ActiveSupport::Concern

  private

  def ensure_registry_token!
    token = session[:auth_token]
    expires_at = session[:auth_token_expires_at]

    return if skip_registry_token_guard?
    return redirect_registry_reauth if token.blank?

    return if expires_at.blank? # allow if expiry not tracked yet

    expiry_time =
      case expires_at
      when Time then expires_at
      when String then Time.zone.parse(expires_at)
      end

    redirect_registry_reauth if expiry_time.nil? || expiry_time <= Time.current
  end

  def skip_registry_token_guard?
    Rails.env.test?
  end

  def redirect_registry_reauth
    sign_out(current_user)
    reset_session

    flash[:alert] = t('errors.registry_session_expired', default: 'Your API session expired. Please sign in again.')
    redirect_to new_user_session_path
  end
end
