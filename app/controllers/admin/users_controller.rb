class Admin::UsersController < Admin::BaseController
  before_action :set_pagy_params
  before_action :store_location, only: %i[show]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_user_not_found

  def index
    @search = User.not_admin.ransack(params[:q])
    @pagy, @users = pagy(@search.result, limit: session[:page_size], page: @page)
  end

  def show
    @user = User.find(params[:id])
    @pagy, @test_attempts = pagy(
      @user.test_attempts.includes(:test).order(created_at: :desc), limit: session[:page_size], page: @page
    )
    @statistics = @user.test_statistics
  end

  private

  def handle_user_not_found
    redirect_to admin_users_path, alert: t('errors.object_not_found')
  end
end
