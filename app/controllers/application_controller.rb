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

  def update_positions
    ActiveRecord::Base.transaction do
      positions = params[:positions]

      positions.each do |id, index|
        model_class.find(id).update(display_order: index)
      end
    end

    respond_to do |format|
      format.json { head :no_content }
      format.turbo_stream
    end
  rescue StandardError => e
    flash.now[:alert] = e.message
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.turbo_stream { render turbo_stream: turbo_stream.update('flash', partial: 'common/flash') }
    end
  end

  private

  def model_class
    controller_name.singularize.classify.constantize
  end

  def ensure_regular_user!
    redirect_to admin_dashboard_path, alert: t(:access_denied_admin) if current_user.admin?
  end

  # Prevent viewing history while a test attempt is in progress for the same account
  def block_history_during_active_attempt!
    return unless current_user

    if current_user.test_attempts.in_progress.exists?
      redirect_to tests_path, alert: I18n.t('tests.history_blocked_while_active')
    end
  end

  protected

  def configure_permitted_parameters
    added_attrs = %i[username email password password_confirmation remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :sign_in, keys: %i[username password]
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
