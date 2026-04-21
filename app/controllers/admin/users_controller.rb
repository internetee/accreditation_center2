class Admin::UsersController < Admin::BaseController
  before_action :set_pagy_params

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
end
