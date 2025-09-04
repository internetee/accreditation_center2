class Admin::TestsController < Admin::BaseController
  before_action :set_test, only: %i[show edit update destroy activate deactivate]
  before_action :set_pagy_params, only: %i[index]

  def index
    @search = Test.ransack(params[:q])
    @pagy, @tests = pagy(@search.result, limit: session[:page_size], page: @page)
  end

  def show
    @test_categories = @test.active_ordered_test_categories_with_join_id
    @recent_attempts = @test.test_attempts.recent.includes(:user).limit(10)
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

  def edit
  end

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
    new_test = @test.dup
    new_test.title_et = "#{@test.title_et} (Copy)"
    new_test.title_en = "#{@test.title_en} (Copy)"
    new_test.active = false
    new_test.display_order = (@test.display_order || 0) + 1

    if new_test.save
      # Duplicate categories and questions
      @test.test_categories.each do |category|
        new_category = category.dup
        new_category.test = new_test
        new_category.save

        # Duplicate questions
        category.questions.each do |question|
          new_question = question.dup
          new_question.test_category = new_category
          new_question.save

          # Duplicate answers
          question.answers.each do |answer|
            new_answer = answer.dup
            new_answer.question = new_question
            new_answer.save
          end
        end
      end

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
      :display_order, :active, test_category_ids: []
    )
  end
end
 