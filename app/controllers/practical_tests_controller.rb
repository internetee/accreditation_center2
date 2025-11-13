class PracticalTestsController < TestsController
  # POST /practical_tests/:id/start
  def start
    super

    redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: 0)
  end

  # GET /practical_tests/:id/question/:question_index
  def question
    load_task_data
    return if redirect_if_task_missing

    @max_allowed_index = calculate_max_allowed_index
    return if redirect_if_navigation_blocked

    show_time_warning_if_needed
  end

  # POST /practical_tests/:id/answer/:question_index
  def answer
    task_index = params[:question_index].to_i
    tasks = @test.practical_tasks.active.ordered
    @current_task = tasks[task_index]
    return head(:not_found) if @current_task.nil?

    ptr = initialize_task_result
    inputs = prepare_inputs
    ptr.save_running_status!(inputs)

    result = run_validator(inputs)
    ptr.persist_result!(result)
    merge_export_vars(result)

    next_index = calculate_next_task_index(task_index, tasks.count)
    redirect_after_result(result, task_index, next_index)
  rescue StandardError => e
    handle_answer_error(ptr, e, task_index)
  end

  # GET /practical_tests/:id/results
  def results
    # Finalize on first visit to results
    return unless @test_attempt.in_progress?

    # Ensure all tasks are solved before completing
    unless @test_attempt.all_tasks_completed?
      first_incompleted = @test_attempt.incompleted_tasks.first
      index = @test.practical_tasks.index(first_incompleted) || 0
      redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: index),
                  alert: t('tests.finish_all_tasks') and return
    end
    @test_attempt.complete!
  end

  private

  def load_task_data
    @tasks = @test.practical_tasks.active.ordered
    @current_task_index = (params[:question_index] || 0).to_i
    @current_task = @tasks[@current_task_index]
  end

  def redirect_if_task_missing
    return false unless @current_task.nil?

    redirect_to results_practical_test_path(@test, attempt: @test_attempt.access_code)
    true
  end

  def calculate_max_allowed_index
    results_by_tid = @test_attempt.practical_task_results.index_by(&:practical_task_id)
    first_pending_index = @tasks.index do |t|
      result = results_by_tid[t.id]
      result.nil? || result.status == 'pending' || result.status == 'failed'
    end
    first_pending_index || (@tasks.count - 1)
  end

  def redirect_if_navigation_blocked
    return false unless @current_task_index > @max_allowed_index && @test_attempt.in_progress?

    redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: @max_allowed_index),
                alert: t('tests.task_current_to_continue')
    true
  end

  def show_time_warning_if_needed
    return unless @test_attempt.time_warning?

    flash.now[:warning] = t('tests.time_warning', minutes: TestAttempt::TIME_WARNING_MINUTES)
  end

  def initialize_task_result
    @test_attempt.practical_task_results.find_or_initialize_by(practical_task: @current_task)
  end

  def prepare_inputs
    raw_inputs = params[:inputs].is_a?(ActionController::Parameters) ? params[:inputs].permit!.to_h : (params[:inputs] || {})
    allowed = @current_task.input_fields.map { |f| f['name'] }
    raw_inputs.to_h.slice(*allowed)
  end

  def run_validator(inputs)
    timeout_seconds = (@current_task.conf['timeout_seconds'] || 60).to_i
    result = nil

    Timeout.timeout(timeout_seconds) do
      validator_klass = @current_task.klass_name.to_s.safe_constantize
      raise "Validator class not found: #{@current_task.klass_name}" unless validator_klass

      validator = validator_klass.new(attempt: @test_attempt, config: @current_task.conf,
                                      inputs: inputs, token: session[:auth_token])
      result = validator.call
    end

    result
  end

  def merge_export_vars(result)
    export_vars = result[:export_vars] || {}
    @test_attempt.merge_vars!(export_vars) if export_vars.present?
  end

  def calculate_next_task_index(current_index, tasks_count)
    next_index = current_index + 1
    next_index >= tasks_count ? current_index : next_index
  end

  def redirect_after_result(result, task_index, next_index)
    if result[:passed]
      flash[:notice] = t('tests.task_passed')
      redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: next_index)
    else
      flash[:alert] = result[:error].presence || t('tests.task_failed')
      redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: task_index)
    end
  end

  def handle_answer_error(ptr, error, task_index)
    ptr.update!(status: :failed, result: (ptr.result || {}).merge('error' => error.message))
    flash[:alert] = error.message
    redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: task_index)
  end
end
