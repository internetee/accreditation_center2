require 'rails_helper'

RSpec.describe 'Admin::TestsController', type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in(admin, scope: :user) }

  describe 'GET /admin/tests' do
    it 'renders the index successfully' do
      test = create(:test, title_et: 'Test Index')

      get admin_tests_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:tests)).to eq([test])
    end
  end

  describe 'GET /admin/tests/:id' do
    it 'renders the show page' do
      test = create(:test)

      get admin_test_path(test)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
      expect(assigns(:test_categories)).to eq(test.test_categories)
      expect(assigns(:practical_tasks)).to eq(test.practical_tasks)
    end
  end

  describe 'GET /admin/tests/new' do
    it 'renders the new page' do
      get new_admin_test_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:test)).to be_a_new(Test)
    end
  end

  describe 'POST /admin/tests' do
    it 'creates a new test and redirects' do
      test_params = attributes_for(:test)

      expect do
        post admin_tests_path, params: { test: test_params }
      end.to change(Test, :count).by(1)

      new_test = Test.order(:created_at).last
      expect(response).to redirect_to(admin_test_path(new_test))
      expect(flash[:notice]).to eq(I18n.t('admin.tests.created'))
    end

    it 'renders the new page with error when creation fails' do
      test_params = attributes_for(:test, title_et: nil)

      post admin_tests_path, params: { test: test_params }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
      expect(flash[:alert]).to eq("Title et (ET) can't be blank")
    end
  end

  describe 'PATCH /admin/tests/:id' do
    it 'updates the test and redirects' do
      test = create(:test, title_et: 'Old Title')

      patch admin_test_path(test), params: { test: { title_et: 'New Title' } }

      expect(response).to redirect_to(admin_test_path(test))
      expect(test.reload.title_et).to eq('New Title')
      expect(flash[:notice]).to eq(I18n.t('admin.tests.updated'))
    end

    it 'renders the edit page with error when update fails' do
      test = create(:test, title_et: 'Old Title')

      patch admin_test_path(test), params: { test: { title_et: nil } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
      expect(flash[:alert]).to eq("Title et (ET) can't be blank")
    end
  end

  describe 'DELETE /admin/tests/:id' do
    it 'destroys the test and redirects' do
      test = create(:test)

      expect do
        delete admin_test_path(test)
      end.to change(Test, :count).by(-1)

      expect(response).to redirect_to(admin_tests_path)
      expect(flash[:notice]).to eq(I18n.t('admin.tests.destroyed'))
    end
  end

  describe 'PATCH /admin/tests/:id/activate' do
    it 'activates the test' do
      test = create(:test, active: false)

      patch activate_admin_test_path(test)

      expect(response).to redirect_to(admin_test_path(test))
      expect(test.reload.active).to be(true)
      expect(flash[:notice]).to eq(I18n.t('admin.tests.activated'))
    end
  end

  describe 'PATCH /admin/tests/:id/deactivate' do
    it 'deactivates the test' do
      test = create(:test, active: true)

      patch deactivate_admin_test_path(test)

      expect(response).to redirect_to(admin_test_path(test))
      expect(test.reload.active).to be(false)
      expect(flash[:notice]).to eq(I18n.t('admin.tests.deactivated'))
    end
  end

  describe 'POST /admin/tests/:id/duplicate' do
    it 'duplicates theoretical test with associations' do
      original = create(:test, title_et: 'Original', title_en: 'Original EN', description_et: 'Desc', description_en: 'Desc EN', active: true)
      category = create(:test_category)
      create(:test_categories_test, test: original, test_category: category)

      expect do
        post duplicate_admin_test_path(original)
      end.to change(Test, :count).by(1)

      duplicated = Test.first
      expect(duplicated.title_et).to include('Original (Copy)')
      expect(duplicated.active).to be(false)
      expect(duplicated.test_categories.count).to eq(1)
      expect(response).to redirect_to(edit_admin_test_path(duplicated))
      expect(flash[:notice]).to eq(I18n.t('admin.tests.duplicated'))
    end

    it 'duplicates practical test with associations' do
      original = create(:test, :practical, title_et: 'Original', title_en: 'Original EN', description_et: 'Desc', description_en: 'Desc EN', active: true)
      create(:practical_task, test: original)

      expect do
        post duplicate_admin_test_path(original)
      end.to change(Test, :count).by(1)

      duplicated = Test.first
      expect(duplicated.title_et).to include('Original (Copy)')
      expect(duplicated.active).to be(false)
      expect(duplicated.practical_tasks.count).to eq(1)
      expect(response).to redirect_to(edit_admin_test_path(duplicated))
      expect(flash[:notice]).to eq(I18n.t('admin.tests.duplicated'))
    end

    it 'renders the duplicate page with error when duplication fails' do
      original = create(:test, title_et: 'Original', title_en: 'Original EN', description_et: 'Desc', description_en: 'Desc EN', active: true)
      invalid_test = build(:test, title_et: nil)
      allow_any_instance_of(Test).to receive(:build_duplicate).and_return(invalid_test)
      post duplicate_admin_test_path(original)

      expect(response).to redirect_to(admin_test_path(original))
      expect(flash[:alert]).to eq(I18n.t('admin.tests.duplication_failed', errors: "Title et (ET) can't be blank"))
    end
  end
end
