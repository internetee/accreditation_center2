class Admin::TestCategoriesController < Admin::BaseController
  before_action :set_test_category, only: [:edit, :update, :destroy, :activate, :deactivate]
  
  def index
    @test_categories = TestCategory.all.ordered
  end
  
  def new
    @test_category = TestCategory.new
  end
  
  def create
    @test_category = TestCategory.new(test_category_params)
    
    if @test_category.save
      redirect_to admin_test_categories_path, notice: t('admin.test_categories.created')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @test_category.update(test_category_params)
      redirect_to admin_test_categories_path, notice: t('admin.test_categories.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @test_category.destroy
    redirect_to admin_test_categories_path, notice: t('admin.test_categories.destroyed')
  end
  
  def activate
    @test_category.update!(active: true)
    redirect_to admin_test_categories_path, notice: t('admin.test_categories.activated')
  end
  
  def deactivate
    @test_category.update!(active: false)
    redirect_to admin_test_categories_path, notice: t('admin.test_categories.deactivated')
  end
  
  private
  
  def set_test_category
    @test_category = TestCategory.find(params[:id])
  end
  
  def test_category_params
    params.require(:test_category).permit(
      :name_et, :name_en, :description_et, :description_en,
      :domain_rule_reference, :questions_per_category, :display_order, :active
    )
  end
end 