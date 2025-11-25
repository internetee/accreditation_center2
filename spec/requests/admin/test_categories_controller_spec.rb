require 'rails_helper'

RSpec.describe 'Admin::TestCategoriesController', type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:test_category) { create(:test_category) }

  before { sign_in admin, scope: :user }

  describe 'GET /admin/test_categories' do
    it 'renders index successfully' do
      get admin_test_categories_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:test_categories)).to include(test_category)
    end
  end

  describe 'GET /admin/test_categories/new' do
    it 'renders the new page' do
      get new_admin_test_category_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:test_category)).to be_a(TestCategory)
    end
  end

  describe 'GET /admin/test_categories/:id' do
    it 'renders show with questions' do
      question = create(:question, test_category: test_category)
      get admin_test_category_path(test_category)

      expect(response).to have_http_status(:ok)
      expect(assigns(:questions)).to include(question)
    end
  end

  describe 'POST /admin/test_categories' do
    it 'creates a new test category' do
      params = attributes_for(:test_category)

      expect do
        post admin_test_categories_path, params: { test_category: params }
      end.to change(TestCategory, :count).by(1)

      expect(response).to redirect_to(admin_test_category_path(TestCategory.last))
      expect(flash[:notice]).to eq(I18n.t('admin.test_categories.created'))
    end

    it 'renders the new page with error when creation fails' do
      params = attributes_for(:test_category, name_et: nil)

      post admin_test_categories_path, params: { test_category: params }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
      expect(flash[:alert]).to eq("Name et (ET) can't be blank")
    end
  end

  describe 'PATCH /admin/test_categories/:id' do
    it 'updates the category' do
      patch admin_test_category_path(test_category), params: { test_category: { name_et: 'Updated' } }

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(test_category.reload.name_et).to eq('Updated')
      expect(flash[:notice]).to eq(I18n.t('admin.test_categories.updated'))
    end

    it 'renders the edit page with error when update fails' do
      patch admin_test_category_path(test_category), params: { test_category: { name_et: nil } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
      expect(flash[:alert]).to eq("Name et (ET) can't be blank")
    end
  end

  describe 'DELETE /admin/test_categories/:id' do
    it 'destroys the category' do
      expect do
        delete admin_test_category_path(test_category)
      end.to change(TestCategory, :count).by(-1)

      expect(response).to redirect_to(admin_test_categories_path)
      expect(flash[:notice]).to eq(I18n.t('admin.test_categories.destroyed'))
    end
  end
end
