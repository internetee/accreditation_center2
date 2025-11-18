class Admin::AnswersController < Admin::BaseController
  before_action :set_test_category
  before_action :set_question
  before_action :set_answer, only: %i[edit update destroy]

  def new
    @answer = @question.answers.build
  end

  def create
    @answer = @question.answers.build(answer_params)
    @answer.display_order = @question.answers.maximum(:display_order).to_i + 1

    respond_to do |format|
      if @answer.save
        format.html { redirect_to admin_test_category_path(@test_category), notice: t('admin.answers.created') }
      else
        flash[:alert] = @answer.errors.full_messages.join(', ')
        format.html { redirect_back_or_to root_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update_all('.dialog_flash', partial: 'common/dialog_flash')
        }
      end
    end
  end

  def edit; end

  def update
    respond_to do |format|
      if @answer.update(answer_params)
        format.html { redirect_to admin_test_category_path(@test_category), notice: t('admin.answers.updated') }
      else
        flash[:alert] = @answer.errors.full_messages.join(', ')
        format.html { redirect_back_or_to root_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update_all('.dialog_flash', partial: 'common/dialog_flash')
        }
      end
    end
  end

  def destroy
    @answer.destroy

    respond_to do |format|
      flash[:notice] = t('admin.answers.destroyed')
      format.html { redirect_to admin_test_category_path(@test_category) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.remove(@answer)
      }
    end
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
