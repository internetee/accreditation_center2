# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # POST /resource/sign_in
  def create
    username = params[:user][:username]
    password = params[:user][:password]

    # Validate input
    if username.blank? || password.blank?
      flash.now[:alert] = t('devise.failure.invalid', authentication_keys: 'username')
      render :new, status: :unauthorized
      return
    end

    user = User.find_by(username: username)

    if user&.valid_password?(password) && user&.admin?
      sign_in(user)
      redirect_after_sign_in(user)
    else
      api_authenticate_user(username, password)
    end
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def api_authenticate_user(username, password)
    auth_service = AuthenticationService.new
    response = auth_service.authenticate_user(username, password)

    unless response[:success]
      flash.now[:alert] = response[:message]
      render :new, status: :unauthorized
      return
    end

    user = User.find_or_initialize_by(username: response[:username])
    if user.new_record?
      user.email = response[:registrar_email]
      user.role = 'user'
      user.password = password
      user.save!
    end

    sign_in(user)
    redirect_after_sign_in(user)
  end

  def redirect_after_sign_in(user)
    if user.admin?
      redirect_to admin_dashboard_path, notice: "Welcome back, #{user.username}!"
    else
      redirect_to root_path, notice: "Welcome back, #{user.username}!"
    end
  end
end
