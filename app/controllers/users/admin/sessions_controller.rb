class Users::Admin::SessionsController < Devise::SessionsController
  # GET /admin/login
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
  end

  # POST /admin/login
  def create
    self.resource = warden.authenticate(auth_options)

    if resource&.admin?
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      sign_out(resource) if resource.present?
      flash.now[:alert] = I18n.t('devise.failure.not_found_in_database')
      self.resource = resource_class.new(sign_in_params)
      clean_up_passwords(resource)
      render :new, status: :unauthorized
    end
  end

  protected

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new", locale: I18n.locale }
  end
end
