require 'rails_helper'

RSpec.describe 'Admin::DashboardController', type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin, scope: :user }

  describe 'GET /admin/dashboard' do
    it 'renders the dashboard and assigns data' do
      test = create(:test)
      test_category = create(:test_category)
      create(:test_categories_test, test: test, test_category: test_category)
      question = create(:question, test_category: test_category)
      create(:answer, question: question, correct: true)
      recent_attempt = create(:test_attempt, test: test)
      expiring_user = create(:user)
      create(:test_attempt, user: expiring_user, test: test, passed: true, created_at: 12.months.ago)

      get admin_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:recent_activity)).to include(recent_attempt)
      expect(assigns(:expiring_accreditations)).to include(expiring_user)
    end
  end
end
