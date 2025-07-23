class Admin::TestAttemptsController < Admin::BaseController
  before_action :set_test
  before_action :set_test_attempt, only: [:show]
  before_action :set_pagy_params, only: %i[index]

  def index
    @pagy, @test_attempts = pagy(@test.test_attempts.includes(:user).ordered, items: session[:page_size], page: @page)
  end

  def show
    @question_responses = @test_attempt.question_responses.includes(:question, :answer)
  end

  private

  def set_test
    @test = Test.find(params[:test_id])
  end

  def set_test_attempt
    @test_attempt = @test.test_attempts.find(params[:id])
  end
end
