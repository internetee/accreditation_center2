class Admin::TestCategoriesController < Admin::BaseController
  before_action :set_test_category, only: %w[show edit update destroy]
  before_action :set_pagy_params, only: %i[index]

  def index
    @search = TestCategory.ransack(params[:q])
    @pagy, @test_categories = pagy(@search.result, limit: session[:page_size], page: @page)
  end

  def new
    @test_category = TestCategory.new
  end

  def create
    @test_category = TestCategory.new(test_category_params)

    if @test_category.save
      redirect_to admin_test_category_path(@test_category), notice: t('admin.test_categories.created')
    else
      flash.now[:alert] = @test_category.errors.full_messages.join(', ')
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def show
    @questions = @test_category.questions.order(display_order: :asc)
    @question = Question.new
  end

  def update
    if @test_category.update(test_category_params)
      redirect_to admin_test_category_path(@test_category), notice: t('admin.test_categories.updated')
    else
      flash.now[:alert] = @test_category.errors.full_messages.join(', ')
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @test_category.destroy
    redirect_to admin_test_categories_path, notice: t('admin.test_categories.destroyed')
  end

  private

  def set_test_category
    @test_category = TestCategory.find(params[:id])
  end

  def test_category_params
    params.require(:test_category).permit(
      :name_et, :name_en, :description_et, :description_en,
      :questions_per_category, :test_type,
      :domain_rule_reference, :domain_rule_url, :display_order, :active
    )
  end
end
