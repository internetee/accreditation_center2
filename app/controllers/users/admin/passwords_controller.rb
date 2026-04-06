class Users::Admin::PasswordsController < Devise::PasswordsController
  # GET /admin/password/new
  def new
    self.resource = resource_class.new
  end

  # POST /admin/password
  def create
    email = resource_params[:email].to_s.strip
    user = User.find_by(email: email)

    unless user&.admin?
      flash.now[:alert] = I18n.t('devise.failure.not_found_in_database', authentication_keys: 'email')
      self.resource = resource_class.new(email: email)
      return render :new, status: :unprocessable_content
    end

    user.send_reset_password_instructions
    redirect_to new_admin_session_path, notice: I18n.t('devise.passwords.send_instructions')
  end

  # PATCH/PUT /admin/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    invalid_token = resource.errors.added?(:reset_password_token, :invalid)

    if resource.errors.empty? && resource.admin?
      set_flash_message!(:notice, :updated)
      redirect_to new_admin_session_path
    else
      # prevent non-admin reset through this endpoint
      resource.errors.add(:base, I18n.t('devise.failure.unauthorized')) if !invalid_token && !resource.admin?
      messages = resource.errors.full_messages
      if invalid_token
        messages = messages.reject { |msg| msg.match?(/reset password token/i) }
        messages << I18n.t('devise.passwords.invalid_token')
      end
      flash.now[:alert] = messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  end

  private

  def resource_params
    params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
  end
end
