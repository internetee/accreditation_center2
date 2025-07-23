class TestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_test, only: [:show, :start, :question, :answer, :finish, :results]
  before_action :set_test_attempt, only: [:question, :answer, :finish, :results]
  before_action :ensure_test_not_expired, only: [:question, :answer]
  before_action :set_locale
  
  def index
    @tests = Test.active.ordered
  end
  
  def show
    @test_attempt = current_user.test_attempts.in_progress.find_by(test: @test)
  end
  
  def start
    # Check if user already has an in-progress attempt
    existing_attempt = current_user.test_attempts.in_progress.find_by(test: @test)
    
    if existing_attempt
      redirect_to question_test_path(@test, attempt: existing_attempt.access_code)
    else
      @test_attempt = current_user.test_attempts.create!(test: @test)
      redirect_to question_test_path(@test, attempt: @test_attempt.access_code)
    end
  end
  
  def question
    @questions = @test.questions.active.ordered
    @current_question_index = params[:question_index]&.to_i || 0
    @current_question = @questions[@current_question_index]
    
    if @current_question.nil?
      redirect_to finish_test_path(@test, attempt: @test_attempt.access_code)
      return
    end
    
    @question_response = @test_attempt.question_responses.find_or_initialize_by(question: @current_question)
    @answers = @current_question.answers.ordered
    
    # Show time warning if needed
    if @test_attempt.time_warning?
      flash.now[:warning] = t('tests.time_warning', minutes: 5)
    end
  end
  
  def answer
    @current_question = @test.questions.active.ordered[params[:question_index].to_i]
    
    if @current_question.nil?
      redirect_to finish_test_path(@test, attempt: @test_attempt.access_code)
      return
    end
    
    @question_response = @test_attempt.question_responses.find_or_initialize_by(question: @current_question)
    
    if params[:marked_for_later]
      @question_response.update!(marked_for_later: true, selected_answer_ids: [])
      flash[:notice] = t('tests.question_marked_for_later')
    else
      selected_answer_ids = params[:answer_ids]&.map(&:to_i) || []
      @question_response.update!(
        selected_answer_ids: selected_answer_ids,
        marked_for_later: false
      )
      flash[:notice] = t('tests.answer_saved')
    end
    
    next_question_index = params[:question_index].to_i + 1
    questions = @test.questions.active.ordered
    
    if next_question_index >= questions.count
      redirect_to finish_test_path(@test, attempt: @test_attempt.access_code)
    else
      redirect_to question_test_path(@test, attempt: @test_attempt.access_code, question_index: next_question_index)
    end
  end
  
  def finish
    if @test_attempt.in_progress?
      @test_attempt.complete!
      @test_attempt.update!(
        score_percentage: @test_attempt.score_percentage,
        passed: @test_attempt.passed?
      )
    end
  end
  
  def results
    @question_responses = @test_attempt.question_responses.includes(:question, :selected_answers)
    @questions = @test.questions.active.ordered
  end
  
  private
  
  def set_test
    @test = Test.active.find(params[:id])
  end
  
  def set_test_attempt
    @test_attempt = current_user.test_attempts.find_by!(
      test: @test,
      access_code: params[:attempt]
    )
  end
  
  def ensure_test_not_expired
    if @test_attempt.time_expired?
      @test_attempt.complete!
      redirect_to finish_test_path(@test, attempt: @test_attempt.access_code), 
                  alert: t('tests.time_expired')
    end
  end
  
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
