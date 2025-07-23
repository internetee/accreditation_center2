class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Localization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  def set_pagy_params
    if params[:per_page]&.to_i&.positive?
      session[:page_size] = params[:per_page].to_i
    else
      session[:page_size] ||= Pagy::DEFAULT[:items]
    end
    @page = params[:page] || 1
    @offset = session[:page_size] * (@page.to_i - 1)
  end

  protected

  def configure_permitted_parameters
    added_attrs = %i[username email password password_confirmation remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :sign_in, keys: %i[username password]
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
