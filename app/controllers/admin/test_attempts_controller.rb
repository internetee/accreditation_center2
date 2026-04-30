class Admin::TestAttemptsController < Admin::BaseController
  before_action :set_test
  before_action :set_test_attempt, only: %i[show extend_time destroy]
  before_action :set_pagy_params, only: %i[index]
  before_action :store_location, only: %i[index]

  def index
    @search = @test.test_attempts.ordered.includes(:user).ransack(params[:q])
    @pagy, @test_attempts = pagy(@search.result, limit: session[:page_size], page: @page)
  end

  def new
    # Get users who haven't been assigned this test yet
    assigned_user_ids = @test.test_attempts.not_completed.reject(&:time_expired?).pluck(:user_id)
    @users = User.not_admin.where.not(id: assigned_user_ids).order(:email)
  end

  def create
    user = User.not_admin.find(test_attempt_params[:user_id])
    @test_attempt = Attempts::Assign.call!(user: user, test: @test)
    redirect_to admin_test_test_attempts_path(@test), notice: t('admin.test_attempts.assigned')
  rescue StandardError => e
    @users = User.not_admin.order(:email)
    flash.now[:alert] = "Error assigning test: #{e.message}"
    render :new, status: :unprocessable_content
  end

  def show
    @question_responses = @test_attempt.question_responses.includes(:question)
    @practical_task_results = @test_attempt.practical_task_results.includes(:practical_task)
  end

  def extend_time
    # Extend the time limit by 30 minutes
    if @test_attempt.in_progress?
      @test_attempt.update!(started_at: @test_attempt.started_at + 30.minutes)
      redirect_to admin_test_test_attempts_path(@test), notice: t('admin.test_attempts.time_extended')
    else
      redirect_to admin_test_test_attempts_path(@test), alert: t('admin.test_attempts.cannot_extend_time')
    end
  end

  def destroy
    @test_attempt.destroy
    redirect_to session[:return_to] || admin_test_test_attempts_path(@test), notice: t('admin.test_attempts.removed')
  end

  private

  def test_attempt_params
    params.require(:test_attempt).permit(:user_id)
  end

  def set_test
    @test = Test.friendly.find(params[:test_id])
  end

  def set_test_attempt
    @test_attempt = @test.test_attempts.find(params[:id])
  end
end
