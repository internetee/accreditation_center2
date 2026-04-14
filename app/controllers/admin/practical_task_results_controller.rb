class Admin::PracticalTaskResultsController < Admin::BaseController
  before_action :set_test
  before_action :set_practical_task, only: %i[index show update]
  before_action :set_practical_task_result, only: %i[show update]
  before_action :set_result_context, only: %i[show update]
  before_action :set_pagy_params, only: %i[index]

  def index
    @search = @practical_task.practical_task_results
                             .includes(:test_attempt)
                             .order(Arel.sql('validated_at DESC NULLS LAST, created_at DESC'))
                             .ransack(params[:q])

    @pagy, @practical_task_results = pagy(@search.result, limit: session[:page_size], page: @page)
  end

  def show; end

  def update
    if feedback_update_locked?
      flash.now[:alert] = t('admin.practical_task_results.show.feedback_locked_after_completion')
      return render :show, status: :unprocessable_content
    end

    @practical_task_result.assign_attributes(practical_task_result_params.except(:feedback))
    @practical_task_result.set_feedback(practical_task_result_params[:feedback], admin: current_user) if practical_task_result_params.key?(:feedback)

    if @practical_task_result.save
      redirect_to admin_test_practical_task_practical_task_result_path(@test, @practical_task, @practical_task_result), 
                  notice: t('admin.practical_task_results.updated')
    else
      render :show, status: :unprocessable_content
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

  def set_result_context
    @test_attempt = @practical_task_result.test_attempt
    @user = @test_attempt.user
  end

  def practical_task_result_params
    params.require(:practical_task_result).permit(:status, :feedback)
  end

  def feedback_update_locked?
    return false unless @test_attempt.completed?

    requested_status = practical_task_result_params[:status].to_s
    status_changed = practical_task_result_params.key?(:status) && requested_status != @practical_task_result.status.to_s

    requested_feedback = practical_task_result_params[:feedback].to_s
    feedback_changed = practical_task_result_params.key?(:feedback) &&
                      requested_feedback != @practical_task_result.feedback.to_s

    status_changed || feedback_changed
  end
end
