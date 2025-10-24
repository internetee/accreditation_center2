class PracticalTestsController < TestsController
  def start
    super

    redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: 0)
  end

  def question
    @tasks = @test.practical_tasks.active.ordered
    @current_task_index = (params[:question_index] || 0).to_i
    @current_task = @tasks[@current_task_index]

    if @current_task.nil?
      redirect_to results_practical_test_path(@test, attempt: @test_attempt.access_code)
      return
    end

    # Determine the first pending task index to restrict forward navigation
    results_by_tid = @test_attempt.practical_task_results.index_by(&:practical_task_id)
    first_pending_index = @tasks.index do |t|
      result = results_by_tid[t.id]
      result.nil? || result.status == 'pending' || result.status == 'failed'
    end
    @max_allowed_index = first_pending_index || (@tasks.count - 1)

    # Prevent navigating past the first pending task
    if @current_task_index > @max_allowed_index
      redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: @max_allowed_index),
                  alert: t('tests.task_current_to_continue') and return
    end

    # Show time warning if needed
    return unless @test_attempt.time_warning?

    flash.now[:warning] = t('tests.time_warning', minutes: 5)
  end

  def answer
    task_index = params[:question_index].to_i
    tasks = @test.practical_tasks.active.ordered
    @current_task = tasks[task_index]
    return head(:not_found) if @current_task.nil?

    # ensure result row exists
    ptr = @test_attempt.practical_task_results.find_or_initialize_by(practical_task: @current_task)

    # permit only declared input fields
    raw_inputs = params[:inputs].is_a?(ActionController::Parameters) ? params[:inputs].permit!.to_h : (params[:inputs] || {})
    inputs = filter_inputs(@current_task, raw_inputs)

    ptr.inputs = inputs
    ptr.status = :running
    ptr.save!

    begin
      timeout_seconds = (@current_task.conf['timeout_seconds'] || 60).to_i

      result = nil
      Timeout.timeout(timeout_seconds) do
        validator_klass = @current_task.klass_name.to_s.safe_constantize
        raise "Validator class not found: #{@current_task.klass_name}" unless validator_klass

        validator = validator_klass.new(
          attempt: @test_attempt,
          config: @current_task.conf,
          inputs: inputs,
          token: session[:auth_token]
        )
        result = validator.call
      end

      # Persist result
      ptr.result = result
      ptr.status = result[:passed] ? :passed : :failed
      ptr.save!

      # Merge exported variables to attempt vars, if any
      export_vars = result[:export_vars] || {}
      @test_attempt.merge_vars!(export_vars) if export_vars.present?

      next_index = task_index + 1
      next_index = task_index if next_index >= tasks.count

      if result[:passed]
        flash[:notice] = t('tests.task_passed')
        redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: next_index)
      else
        flash[:alert] = result[:error].presence || t('tests.task_failed')
        redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: task_index)
      end
    rescue Timeout::Error
      ptr.update!(status: :failed, result: (ptr.result || {}).merge('error' => t('tests.validation_timeout')))
      flash[:alert] = t('tests.validation_timeout')
      redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: task_index)
    rescue => e
      ptr.update!(status: :failed, result: (ptr.result || {}).merge('error' => e.message))
      flash[:alert] = e.message
      redirect_to question_practical_test_path(@test, attempt: @test_attempt.access_code, question_index: task_index)
    end
  end

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
    @test_attempt.update!(
      score_percentage: @test_attempt.score_percentage,
      passed: @test_attempt.passed?
    )
  end

  private

  def filter_inputs(task, raw)
    allowed = task.input_fields.map { |f| f['name'] }
    raw.to_h.slice(*allowed)
  end
end
