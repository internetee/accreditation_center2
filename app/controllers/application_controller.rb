class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Localization
  include RegistryTokenGuard

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ApiConnector::UnauthorizedError, with: :handle_api_unauthorized

  def set_pagy_params
    session[:page_size] = computed_page_size
    @page = (params[:page] || 1).to_i
    @offset = session[:page_size] * (@page - 1)
  end

  def update_positions
    update_records!
    respond_successfully
  rescue StandardError => e
    handle_update_error(e)
  end

  private

  def handle_api_unauthorized
    sign_out(current_user) if user_signed_in?
    reset_session
    redirect_to new_user_session_path, alert: t('errors.invalid_credentials')
  end

  def model_class
    controller_name.singularize.classify.constantize
  end

  def ensure_regular_user!
    redirect_to admin_dashboard_path, alert: t(:access_denied_admin) if current_user&.admin?
  end

  def update_records!
    ActiveRecord::Base.transaction do
      params[:positions].each do |id, index|
        model_class.find(id).update(display_order: index)
      end
    end
  end

  def respond_successfully
    respond_to do |format|
      format.json { head :no_content }
      format.turbo_stream
    end
  end

  def handle_update_error(error)
    flash.now[:alert] = error.message
    respond_to do |format|
      format.json { render json: { error: error.message }, status: :unprocessable_content }
      format.turbo_stream { render turbo_stream: turbo_stream.update('flash', partial: 'common/flash') }
    end
  end

  def computed_page_size
    per_page = params[:per_page].to_i
    return per_page if per_page.positive?

    session[:page_size] ||= Pagy::DEFAULT[:items]
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  protected

  def configure_permitted_parameters
    added_attrs = %i[email name]
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end

  def after_sign_in_path_for(resource)
    stored_location = stored_location_for(resource)
    return stored_location if stored_location

    if resource.admin?
      admin_dashboard_path
    else
      root_path
    end
  end

  def after_sign_out_path_for(*)
    new_user_session_path
  end
end
