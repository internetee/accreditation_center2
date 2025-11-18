class Admin::TestsController < Admin::BaseController
  before_action :set_test, only: %i[show edit update destroy activate deactivate duplicate]
  before_action :set_pagy_params, only: %i[index]

  def index
    @search = Test.ransack(params[:q])
    @pagy, @tests = pagy(@search.result, limit: session[:page_size], page: @page)
  end

  def show
    @test_categories = @test.active_ordered_test_categories_with_join_id
    @practical_tasks = @test.practical_tasks.ordered
    # @recent_attempts = @test.test_attempts.recent.includes(:user).limit(10)
  end

  def new
    @test = Test.new
  end

  def create
    @test = Test.new(test_params)

    if @test.save
      redirect_to admin_test_path(@test), notice: t('admin.tests.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @test.update(test_params)
      redirect_to admin_test_path(@test), notice: t('admin.tests.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @test.destroy
    redirect_to admin_tests_path, notice: t('admin.tests.destroyed')
  end

  def activate
    @test.update!(active: true)
    redirect_to admin_test_path(@test), notice: t('admin.tests.activated')
  end

  def deactivate
    @test.update!(active: false)
    redirect_to admin_test_path(@test), notice: t('admin.tests.deactivated')
  end

  def duplicate
    new_test = @test.build_duplicate

    if new_test.save
      duplicate_associations(new_test)
      redirect_to edit_admin_test_path(new_test), notice: t('admin.tests.duplicated')
    else
      redirect_to admin_test_path(@test), alert: t('admin.tests.duplication_failed')
    end
  end

  private

  def set_test
    @test = Test.friendly.find(params[:id])
  end

  def test_params
    params.require(:test).permit(
      :title_et, :title_en, :description_et, :description_en,
      :time_limit_minutes, :questions_per_category, :passing_score_percentage,
      :display_order, :active, :test_type, test_category_ids: []
    )
  end

  def duplicate_associations(new_test)
    duplicate_test_categories(new_test)
    duplicate_practical_tasks(new_test)
  end

  def duplicate_test_categories(new_test)
    @test.test_categories_tests.find_each do |category_test|
      new_category_test = category_test.dup
      new_category_test.test = new_test
      new_category_test.save!
    end
  end

  def duplicate_practical_tasks(new_test)
    return unless @test.practical?

    @test.practical_tasks.find_each do |task|
      new_task = task.dup
      new_task.test = new_test
      new_task.display_order = task.display_order
      new_task.save!
    end
  end
end
