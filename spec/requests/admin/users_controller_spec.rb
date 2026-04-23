require 'rails_helper'

RSpec.describe 'Admin::UsersController', type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:user) { create(:user) }

  before { sign_in(admin, scope: :user) }

  describe 'GET /admin/users' do
    it 'renders index with users' do
      get admin_users_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:users)).to include(user)
    end
  end

  describe 'GET /admin/users/:id' do
    it 'renders show with attempts and statistics' do
      test = create(:test)
      test_category = create(:test_category)
      question = create(:question, test_category: test_category)
      create(:answer, question: question, correct: true)
      create(:test_categories_test, test: test, test_category: test_category)
      attempt = create(:test_attempt, user: user, test: test)

      get admin_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(assigns(:test_attempts)).to include(attempt)
      expect(assigns(:statistics)).to eq(user.test_statistics)
      expect(session[:return_to]).to eq(admin_user_path(user))
    end

    it 'orders attempts by created_at desc' do
      test = create(:test)
      test_category = create(:test_category)
      question = create(:question, test_category: test_category)
      create(:answer, question: question, correct: true)
      create(:test_categories_test, test: test, test_category: test_category)
      old_attempt = create(:test_attempt, user: user, test: test, created_at: 2.days.ago)
      new_attempt = create(:test_attempt, user: user, test: test, created_at: 1.day.ago)

      get admin_user_path(user)

      expect(assigns(:test_attempts).to_a.first).to eq(new_attempt)
      expect(assigns(:test_attempts).to_a.second).to eq(old_attempt)
    end

    it 'redirects non-admin user to root with alert' do
      sign_out :user
      sign_in create(:user)

      get admin_user_path(user)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
    end

    it 'returns not found when user does not exist' do
      get admin_user_path(id: 0)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to eq(I18n.t('errors.object_not_found'))
    end
  end
end
