class Admin::PracticalTasksController < Admin::BaseController
  before_action :set_test
  before_action :set_practical_task, only: %i[edit update destroy show]

  def new
    @practical_task = @test.practical_tasks.build
  end

  def create
    return render_invalid_validator_json unless normalize_validator_json!

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
    return render_invalid_validator_json unless normalize_validator_json!

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

  def show; end

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
      :display_order, :active, validator: {}
    )
  end

  def normalize_validator_json!
    raw = params.dig(:practical_task, :validator)
    return true unless raw.is_a?(String)

    stripped = raw.strip
    params[:practical_task][:validator] = stripped.present? ? JSON.parse(stripped) : {}
    true
  rescue JSON::ParserError
    false
  end

  def render_invalid_validator_json
    flash[:alert] = t('admin.practical_tasks.invalid_validator_json', default: 'Validator must be valid JSON')

    respond_to do |format|
      format.html { redirect_back_or_to root_path }
      format.turbo_stream {
        render turbo_stream: turbo_stream.update_all('.dialog_flash', partial: 'common/dialog_flash')
      }
    end
  end
end
