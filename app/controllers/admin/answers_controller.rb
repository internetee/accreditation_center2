class Admin::AnswersController < Admin::BaseController
  before_action :set_test_category
  before_action :set_question
  before_action :set_answer, only: [:edit, :update, :destroy]
  
  def index
    @answers = @question.answers.ordered
  end
  
  def new
    @answer = @question.answers.build
  end
  
  def create
    @answer = @question.answers.build(answer_params)
    
    if @answer.save
      redirect_to admin_test_category_question_answers_path(@test_category, @question), notice: t('admin.answers.created')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @answer.update(answer_params)
      redirect_to admin_test_category_question_answers_path(@test_category, @question), notice: t('admin.answers.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @answer.destroy
    redirect_to admin_test_category_question_answers_path(@test_category, @question), notice: t('admin.answers.destroyed')
  end
  
  def reorder
    params[:answer_ids].each_with_index do |answer_id, index|
      Answer.where(id: answer_id).update_all(display_order: index + 1)
    end
    
    head :ok
  end
  
  private
  
  def set_test_category
    @test_category = TestCategory.find(params[:test_category_id])
  end
  
  def set_question
    @question = @test_category.questions.find(params[:question_id])
  end
  
  def set_answer
    @answer = @question.answers.find(params[:id])
  end
  
  def answer_params
    params.require(:answer).permit(:text_et, :text_en, :display_order, :correct)
  end
end 