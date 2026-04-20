# frozen_string_literal: true

class TheoreticalTestsController < TestsController
  # POST /theoretical_tests/:id/start
  def start
    super
    @test_attempt.initialize_question_set!
    redirect_to question_theoretical_test_path(@test, attempt: @test_attempt.access_code, question_index: 0)
  end

  # GET /theoretical_tests/:id/question/:question_index
  def question
    load_question_data
    return if redirect_if_question_missing

    @max_allowed_index = calculate_max_allowed_index
    return if redirect_if_navigation_blocked

    load_question_response_data
    show_time_warning_if_needed
  end

  # POST /theoretical_tests/:id/answer/:question_index
  def answer
    question_index = params[:question_index].to_i
    current_question = @test_attempt.questions[question_index]
    return head(:not_found) if current_question.nil?

    question_response = @test_attempt.question_responses.find_or_initialize_by(question: current_question)
    update_question_response(question_response, question_index)
  end

  # GET /theoretical_tests/:id/results
  def results
    # Finalize on first visit to results
    if @test_attempt.in_progress?
      # Ensure all questions are answered before completing
      unless @test_attempt.all_questions_answered?
        first_unanswered = @test_attempt.unanswered_questions.first
        index = @test_attempt.questions.index(first_unanswered) || 0
        redirect_to question_theoretical_test_path(@test, attempt: @test_attempt.access_code, question_index: index),
                    alert: t('tests.answer_all_questions') and return
      end
      @test_attempt.complete!
    end

    load_results_data
  end

  private

  def update_question_response(question_response, question_index)
    selected_answer_ids = params[:answer_id] ? [params[:answer_id].to_i] : []
    marked_for_later = params[:marked_for_later].present?

    if question_response.update(marked_for_later: marked_for_later, selected_answer_ids: selected_answer_ids)
      flash[:notice] = marked_for_later ? t('tests.question_marked_for_later') : t('tests.answer_saved')
      redirect_to question_path(calculate_next_question_index(question_index))
    else
      flash[:alert] = question_response.errors.full_messages.join(', ')
      redirect_to question_path(question_index)
    end
  end

  def calculate_next_question_index(current_index)
    next_index = current_index + 1
    questions = @test_attempt.questions
    next_index >= questions.count ? current_index : next_index
  end

  def question_path(question_index)
    question_theoretical_test_path(@test, attempt: @test_attempt.access_code, question_index: question_index)
  end

  def handle_answer_error(error, question_index)
    flash[:alert] = error.message
    redirect_to question_path(question_index)
  end

  def load_question_data
    @questions = @test_attempt.questions
    @current_question_index = (params[:question_index] || 0).to_i
    @current_question = @questions[@current_question_index]
  end

  def redirect_if_question_missing
    return false unless @current_question.nil?

    redirect_to results_theoretical_test_path(@test, attempt: @test_attempt.access_code)
    true
  end

  def calculate_max_allowed_index
    responses_by_qid = @test_attempt.question_responses.index_by(&:question_id)
    first_unanswered_index = @questions.index do |q|
      resp = responses_by_qid[q.id]
      resp.nil? || (resp.selected_answer_ids.blank? && !resp.marked_for_later?)
    end
    first_unanswered_index || (@questions.count - 1)
  end

  def redirect_if_navigation_blocked
    return false unless @current_question_index > @max_allowed_index && @test_attempt.in_progress?

    redirect_to question_path(@max_allowed_index), alert: t('tests.answer_current_to_continue')
    true
  end

  def load_question_response_data
    @question_response = @test_attempt.question_responses.find_or_initialize_by(question: @current_question)
    @answers = @current_question.answers.ordered
  end

  def show_time_warning_if_needed
    return unless @test_attempt.time_warning?

    flash.now[:warning] = t('tests.time_warning', minutes: TestAttempt::TIME_WARNING_MINUTES)
  end

  def load_results_data
    # If older than 30 days, do not show detailed responses
    if @test_attempt.details_expired?
      @question_responses = []
      @questions = []
    else
      @question_responses = @test_attempt.question_responses.includes(:question)
      @questions = @test_attempt.questions
    end
  end
end
