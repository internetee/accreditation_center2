class Admin::UsersController < Admin::BaseController
  before_action :set_pagy_params
  before_action :store_location, only: %i[show]
  before_action :set_user, only: %i[show destroy]
  before_action :set_registrars, only: %i[new create]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_user_not_found

  def index
    @search = User.ransack(params[:q])
    @pagy, @users = pagy(@search.result, limit: session[:page_size], page: @page)
  end

  def show
    @pagy, @test_attempts = pagy(
      @user.test_attempts.includes(:test).order(created_at: :desc), limit: session[:page_size], page: @page
    )
    @statistics = @user.test_statistics
  end

  def new
    @user = User.new(role: :user)
  end

  def create
    @user = User.new(user_params)
    normalize_user_creation_params

    if @user.save
      redirect_to admin_user_path(@user), notice: t('.success', default: 'User was created successfully.')
    else
      flash.now[:alert] = @user.errors.full_messages.join(', ')
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_user_path(@user), alert: t('.self_deletion_forbidden', default: 'You cannot delete your own account.')
      return
    end

    @user.destroy!
    redirect_to admin_users_path, notice: t('.success', default: 'User was deleted successfully.')
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_registrars
    @registrars = Registrar.order(:name)
  end

  def user_params
    params.require(:user).permit(:name, :email, :username, :role, :provider, :uid, :password, :password_confirmation, :registrar_id)
  end

  def normalize_user_creation_params
    @user.username = nil if @user.username.blank?

    if @user.admin?
      @user.provider = nil if @user.provider.blank?
      @user.uid = nil if @user.uid.blank?
      return
    end

    @user.provider = @user.provider.presence || 'oidc'
    @user.uid = @user.uid.presence || generated_user_uid
  end

  def generated_user_uid
    loop do
      candidate = "MANUAL#{SecureRandom.alphanumeric(10).upcase}"
      break candidate unless User.exists?(uid: candidate, provider: @user.provider)
    end
  end

  def handle_user_not_found
    redirect_to admin_users_path, alert: t('errors.object_not_found')
  end
end
