class Admin::TestAttemptsController < Admin::BaseController
  before_action :set_test, except: [:show]
  before_action :set_test_attempt, only: %i[show reassign extend_time destroy]
  before_action :set_pagy_params, only: %i[index]

  def index
    @pagy, @test_attempts = pagy(@test.test_attempts.includes(:user).ordered, items: session[:page_size], page: @page)
  end

  def new
    # Get users who haven't been assigned this test yet
    assigned_user_ids = @test.test_attempts.not_completed.pluck(:user_id)
    @users = User.not_admin.where.not(id: assigned_user_ids).order(:email)
  end

  def create
    user = User.not_admin.find(test_attempt_params[:user_id])
    @test_attempt = Attempts::Assign.call!(user: user, test: @test)
    redirect_to admin_test_test_attempts_path(@test), notice: t('admin.test_attempts.assigned')
  rescue => e
    @users = User.not_admin.order(:email)
    flash.now[:alert] = "Error assigning test: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def show
    @question_responses = @test_attempt.question_responses.includes(:question, :answers)
  end

  def reassign
    # Duplicate the test_attempt for the same user and test, including its attributes except id, timestamps, and status
    new_attempt = @test_attempt.dup
    new_attempt.started_at = nil
    new_attempt.completed_at = nil
    new_attempt.passed = nil
    new_attempt.score_percentage = nil
    new_attempt.access_code = SecureRandom.hex(8)

    if new_attempt.save
      redirect_to admin_test_test_attempts_path(@test), notice: t('admin.test_attempts.reassigned')
    else
      redirect_to admin_test_test_attempts_path(@test), alert: t('admin.test_attempts.reassign_failed')
    end
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
    redirect_to admin_test_test_attempts_path(@test), notice: t('admin.test_attempts.removed')
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
