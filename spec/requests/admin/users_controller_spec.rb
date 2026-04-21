require 'rails_helper'

RSpec.describe 'Admin::UsersController', type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:user) { create(:user) }

  before { sign_in admin, scope: :user }

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
    end
  end
end
