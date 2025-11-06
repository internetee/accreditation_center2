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
    # Only the randomized set for this attempt
    @questions = @test_attempt.questions
    @current_question_index = (params[:question_index] || 0).to_i
    @current_question = @questions[@current_question_index]

    if @current_question.nil?
      redirect_to results_theoretical_test_path(@test, attempt: @test_attempt.access_code)
      return
    end

    # Determine the first unanswered question index to restrict forward navigation
    responses_by_qid = @test_attempt.question_responses.index_by(&:question_id)
    first_unanswered_index = @questions.index do |q|
      resp = responses_by_qid[q.id]
      resp.nil? || (resp.selected_answer_ids.blank? && !resp.marked_for_later?)
    end
    @max_allowed_index = first_unanswered_index || (@questions.count - 1)

    # Prevent navigating past the first unanswered question
    if @current_question_index > @max_allowed_index && @test_attempt.in_progress?
      redirect_to question_theoretical_test_path(@test, attempt: @test_attempt.access_code, question_index: @max_allowed_index),
                  alert: t('tests.answer_current_to_continue') and return
    end

    @question_response = @test_attempt.question_responses.find_or_initialize_by(question: @current_question)
    @answers = @current_question.answers.ordered

    # Show time warning if needed
    return unless @test_attempt.time_warning?

    flash.now[:warning] = t('tests.time_warning', minutes: TestAttempt::TIME_WARNING_MINUTES)
  end

  # POST /theoretical_tests/:id/answer/:question_index
  def answer
    @current_question = @test_attempt.questions[params[:question_index].to_i]
    return head(:not_found) if @current_question.nil?

    @question_response = @test_attempt.question_responses.find_or_initialize_by(question: @current_question)

    if params[:marked_for_later]
      @question_response.update!(marked_for_later: true, selected_answer_ids: [])
      flash[:notice] = t('tests.question_marked_for_later')
    else
      # Handle multiple choice question response
      selected_answer_ids = params[:answer_id] ? [params[:answer_id].to_i] : []
      @question_response.update!(
        selected_answer_ids: selected_answer_ids,
        marked_for_later: false
      )
      flash[:notice] = t('tests.answer_saved')
    end

    next_question_index = params[:question_index].to_i + 1
    questions = @test_attempt.questions

    next_question_index = params[:question_index].to_i if next_question_index >= questions.count

    redirect_to question_theoretical_test_path(@test, attempt: @test_attempt.access_code, question_index: next_question_index)
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.message
    redirect_to question_theoretical_test_path(@test, attempt: @test_attempt.access_code, question_index: params[:question_index].to_i)
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
