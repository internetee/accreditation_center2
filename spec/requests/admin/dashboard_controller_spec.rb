require 'rails_helper'

RSpec.describe 'Admin::DashboardController', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:test) { create(:test) }
  let(:test_category) { create(:test_category) }
  let!(:test_categories_test) { create(:test_categories_test, test: test, test_category: test_category) }
  let!(:question) { create(:question, test_category: test_category) }
  let!(:answer) { create(:answer, question: question, correct: true) }

  before do
    sign_in admin, scope: :user
    ENV['ACCR_EXPIRY_NOTIFICATION_DAYS'] = '14'
  end

  describe 'GET /admin/dashboard' do
    context 'when loading dashboard data' do
      let!(:recent_attempt) { create(:test_attempt, test: test) }

      it 'renders the dashboard and assigns recent activity and expiring accreditations' do
        expiring_user = create(:user, accreditation_expire_date: 14.days.from_now)
        create(:test_attempt, user: expiring_user, test: test, passed: true, created_at: 12.months.ago)

        get admin_dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:recent_activity)).to include(recent_attempt)
        expect(assigns(:expiring_accreditations)).to include(expiring_user)
      end

      it 'does not include users with expiring accreditations outside the configured range' do
        expiring_user = create(:user, accreditation_expire_date: 15.days.from_now)
        create(:test_attempt, user: expiring_user, test: test, passed: true, created_at: 12.months.ago)

        get admin_dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:expiring_accreditations)).not_to include(expiring_user)
      end
    end

    it 'redirects to root path when user is not admin' do
      sign_out :user
      sign_in create(:user), scope: :user
      get admin_dashboard_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
    end
  end
end
