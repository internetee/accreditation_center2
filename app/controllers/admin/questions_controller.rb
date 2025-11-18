class Admin::QuestionsController < Admin::BaseController
  before_action :set_test_category
  before_action :set_question, only: %i[edit update destroy]

  def new
    @question = @test_category.questions.build
    @question.answers.build
  end

  def create
    @question = @test_category.questions.build(question_params)
    @question.display_order = @test_category.questions.maximum(:display_order).to_i + 1

    respond_to do |format|
      if @question.save
        format.html { redirect_to admin_test_category_path(@test_category), notice: t('admin.questions.created') }
      else
        @question.answers.build if @question.answers.empty?
        flash[:alert] = @question.errors.full_messages.join(', ')
        format.html { redirect_back_or_to root_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update_all('.dialog_flash', partial: 'common/dialog_flash')
        }
      end
    end
  end

  def edit
    @question.answers.build if @question.answers.empty?
  end

  def update
    respond_to do |format|
      if @question.update(question_params)
        format.html { redirect_to admin_test_category_path(@test_category), notice: t('admin.questions.updated') }
      else
        @question.answers.build if @question.answers.empty?
        flash[:alert] = @question.errors.full_messages.join(', ')
        format.html { redirect_back_or_to root_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update_all('.dialog_flash', partial: 'common/dialog_flash')
        }
      end
    end
  end

  def destroy
    @question.destroy

    respond_to do |format|
      flash[:notice] = t('admin.questions.destroyed')
      format.html { redirect_to admin_test_category_path(@test_category) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.remove(@question)
      }
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
      :text_et, :text_en, :help_text_et, :help_text_en, :active,
      answers_attributes: %i[id text_et text_en display_order correct _destroy]
    )
  end
end
