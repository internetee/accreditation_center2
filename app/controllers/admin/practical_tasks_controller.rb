class Admin::PracticalTasksController < Admin::BaseController
  before_action :set_test
  before_action :set_practical_task, only: %i[edit update destroy]

  def new
    @practical_task = @test.practical_tasks.build
  end

  def create
    @practical_task = @test.practical_tasks.build(practical_task_params)
    @practical_task.display_order = @test.practical_tasks.maximum(:display_order).to_i + 1

    respond_to do |format|
      if @practical_task.save
        format.html { redirect_to admin_test_path(@test), notice: t('admin.practical_tasks.created') }
      else
        flash[:alert] = @practical_task.errors.full_messages.join(', ')
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
      if @practical_task.update(practical_task_params)
        format.html { redirect_to admin_test_path(@test), notice: t('admin.practical_tasks.updated') }
      else
        flash[:alert] = @practical_task.errors.full_messages.join(', ')
        format.html { redirect_back_or_to root_path }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update_all('.dialog_flash', partial: 'common/dialog_flash')
        }
      end
    end
  end

  def destroy
    @practical_task.destroy
    redirect_to admin_test_path(@test), notice: t('admin.practical_tasks.destroyed')
  end

  private

  def set_test
    @test = Test.friendly.find(params[:test_id])
  end

  def set_practical_task
    @practical_task = @test.practical_tasks.find(params[:id])
  end

  def practical_task_params
    params.require(:practical_task).permit(
      :title_et, :title_en, :body_et, :body_en,
      :validator, :display_order, :active
    )
  end
end
