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

  describe 'GET /admin/users/new' do
    it 'renders the new user form' do
      get new_admin_user_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST /admin/users' do
    it 'creates a regular user with minimal required attributes' do
      expect do
        post admin_users_path, params: {
          user: {
            role: 'user',
            name: 'Manual User'
          }
        }
      end.to change(User, :count).by(1)

      created_user = User.order(:id).last
      expect(response).to redirect_to(admin_user_path(created_user))
      expect(created_user.role).to eq('user')
      expect(created_user.provider).to eq('oidc')
      expect(created_user.uid).to be_present
    end

    it 'creates an admin user with email and password' do
      expect do
        post admin_users_path, params: {
          user: {
            role: 'admin',
            name: 'Manual Admin',
            email: 'manual-admin@example.test',
            password: 'AdminPass123!',
            password_confirmation: 'AdminPass123!'
          }
        }
      end.to change(User, :count).by(1)

      created_user = User.order(:id).last
      expect(response).to redirect_to(admin_user_path(created_user))
      expect(created_user.role).to eq('admin')
    end
  end

  describe 'DELETE /admin/users/:id' do
    it 'deletes another user and redirects to index with notice' do
      test = create(:test)
      test_category = create(:test_category)
      question = create(:question, test_category: test_category)
      create(:answer, question: question, correct: true)
      create(:test_categories_test, test: test, test_category: test_category)
      test_attempt = create(:test_attempt, user: user, test: test)
      question_response = create(:question_response, test_attempt: test_attempt)
      practical_task = create(:practical_task, test: create(:test, :practical))
      practical_task_result = create(:practical_task_result, test_attempt: test_attempt, practical_task: practical_task)

      delete admin_user_path(user)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:notice]).to be_present
      expect(User.exists?(user.id)).to be(false)
      expect(TestAttempt.exists?(test_attempt.id)).to be(false)
      expect(QuestionResponse.exists?(question_response.id)).to be(false)
      expect(PracticalTaskResult.exists?(practical_task_result.id)).to be(false)
    end

    it 'does not allow an admin to delete their own account' do
      delete admin_user_path(admin)

      expect(response).to redirect_to(admin_user_path(admin))
      expect(flash[:alert]).to be_present
      expect(User.exists?(admin.id)).to be(true)
    end

    it 'redirects non-admin user to root with alert' do
      sign_out :user
      sign_in create(:user)

      delete admin_user_path(user)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
      expect(User.exists?(user.id)).to be(true)
    end

    it 'redirects unauthenticated user to login' do
      sign_out :user

      delete admin_user_path(user)

      expect(response).to redirect_to(new_user_session_path)
      expect(User.exists?(user.id)).to be(true)
    end

    it 'returns not found when user does not exist' do
      delete admin_user_path(id: 0)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to eq(I18n.t('errors.object_not_found'))
    end
  end
end
