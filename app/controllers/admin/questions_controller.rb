class Admin::QuestionsController < Admin::BaseController
  before_action :set_test_category
  before_action :set_question, only: [:edit, :update, :destroy, :activate, :deactivate]
  
  def index
    @questions = @test_category.questions.ordered
  end
  
  def new
    @question = @test_category.questions.build
    @question.answers.build
  end
  
  def create
    @question = @test_category.questions.build(question_params)
    
    if @question.save
      redirect_to admin_test_category_questions_path(@test_category), notice: t('admin.questions.created')
    else
      @question.answers.build if @question.answers.empty?
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @question.answers.build if @question.answers.empty?
  end
  
  def update
    if @question.update(question_params)
      redirect_to admin_test_category_questions_path(@test_category), notice: t('admin.questions.updated')
    else
      @question.answers.build if @question.answers.empty?
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @question.destroy
    redirect_to admin_test_category_questions_path(@test_category), notice: t('admin.questions.destroyed')
  end
  
  def activate
    @question.update!(active: true)
    redirect_to admin_test_category_questions_path(@test_category), notice: t('admin.questions.activated')
  end
  
  def deactivate
    @question.update!(active: false)
    redirect_to admin_test_category_questions_path(@test_category), notice: t('admin.questions.deactivated')
  end
  
  def duplicate
    original_question = @test_category.questions.find(params[:id])
    @question = original_question.dup
    @question.text_et = "#{original_question.text_et} (copy)"
    @question.text_en = "#{original_question.text_en} (copy)"
    @question.display_order = @test_category.questions.maximum(:display_order).to_i + 1
    
    if @question.save
      # Duplicate answers
      original_question.answers.each do |answer|
        new_answer = answer.dup
        new_answer.question = @question
        new_answer.save
      end
      
      redirect_to admin_test_category_questions_path(@test_category), notice: t('admin.questions.duplicated')
    else
      redirect_to admin_test_category_questions_path(@test_category), alert: t('admin.questions.duplication_failed')
    end
  end
  
  private
  
  def set_test_category
    @test_category = TestCategory.find(params[:test_category_id])
  end
  
  def set_question
    @question = @test_category.questions.find(params[:id])
  end
  
  def question_params
    params.require(:question).permit(
      :text_et, :text_en, :help_text_et, :help_text_en,
      :question_type, :display_order, :active,
      :practical_task_data,
      answers_attributes: [:id, :text_et, :text_en, :display_order, :correct, :_destroy]
    )
  end
end 