class Admin::PracticalTaskResultsController < Admin::BaseController
  before_action :set_test
  before_action :set_practical_task, only: %i[index show]
  before_action :set_practical_task_result, only: %i[show update]

  def index
    @practical_task_results = @practical_task.practical_task_results
                                           .includes(:test_attempt, :user)
                                           .order(created_at: :desc)
    
    @pagy, @practical_task_results = pagy(@practical_task_results, limit: session[:page_size], page: @page)
  end

  def show
    @test_attempt = @practical_task_result.test_attempt
    @user = @test_attempt.user
  end

  def update
    if @practical_task_result.update(practical_task_result_params)
      redirect_to admin_test_practical_task_practical_task_result_path(@test, @practical_task, @practical_task_result), 
                  notice: t('admin.practical_task_results.updated')
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_test
    @test = Test.friendly.find(params[:test_id])
  end

  def set_practical_task
    @practical_task = @test.practical_tasks.find(params[:practical_task_id])
  end

  def set_practical_task_result
    @practical_task_result = @practical_task.practical_task_results.find(params[:id])
  end

  def practical_task_result_params
    params.require(:practical_task_result).permit(:status, :score, :feedback, :response_data)
  end
end
