class Admin::RegistrarsController < Admin::BaseController
  before_action :set_pagy_params
  rescue_from ActiveRecord::RecordNotFound, with: :handle_registrar_not_found

  def index
    @search = Registrar.ransack(params[:q])
    @pagy, @registrars = pagy(@search.result(distinct: true).includes(:users), limit: session[:page_size], page: @page)
  end

  def show
    @registrar = Registrar.includes(:users, :registrar_notification_events).find(params[:id])
    @registrar_users = @registrar.users.order(:name)
    @registrar_notification_events = @registrar.registrar_notification_events.order(sent_at: :desc)
  end

  private

  def handle_registrar_not_found
    redirect_to admin_registrars_path, alert: t('errors.object_not_found')
  end
end
