require 'rails_helper'

RSpec.describe 'Admin::DashboardController', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:test) { create(:test) }
  let(:test_category) { create(:test_category) }
  let!(:test_categories_test) { create(:test_categories_test, test: test, test_category: test_category) }
  let!(:question) { create(:question, test_category: test_category) }
  let!(:answer) { create(:answer, question: question, correct: true) }

  before do
    sign_in(admin, scope: :user)
    ENV['ACCR_EXPIRY_NOTIFICATION_DAYS'] = '14'
  end

  describe 'GET /admin/dashboard' do
    context 'when loading dashboard data' do
      let!(:recent_attempt) { create(:test_attempt, test: test) }

      it 'renders the dashboard and assigns recent activity and expiring accreditations' do
        expiring_registrar = create(:registrar, accreditation_expire_date: 14.days.from_now)
        expiring_user = create(:user, registrar: expiring_registrar)
        create(:test_attempt, user: expiring_user, test: test, passed: true, created_at: 12.months.ago)

        get admin_dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:recent_activity)).to include(recent_attempt)
        expect(assigns(:expiring_accreditations)).to include(expiring_registrar)
      end

      it 'does not include users with expiring accreditations outside the configured range' do
        expiring_user = create(:user, registrar: create(:registrar, accreditation_expire_date: 15.days.from_now))
        create(:test_attempt, user: expiring_user, test: test, passed: true, created_at: 12.months.ago)

        get admin_dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:expiring_accreditations)).not_to include(expiring_user.registrar)
      end

      it 'shows expiring accreditations section with registrar details' do
        expiring_registrar = create(:registrar, name: 'Registrar Ltd', accreditation_expire_date: 7.days.from_now)
        expiring_user = create(:user, registrar: expiring_registrar)
        create(:test_attempt, user: expiring_user, test: test, passed: true, created_at: 2.days.ago)

        get admin_dashboard_path

        expect(response.body).to include(I18n.t('admin.dashboard.expiring_accreditations'))
        expect(response.body).to include(I18n.t('admin.dashboard.registrar'))
        expect(response.body).to include(I18n.t('admin.dashboard.days_until_expiry'))
        expect(response.body).to include('Registrar Ltd')
        expect(response.body).to include(I18n.t('admin.dashboard.accreditation_expires'))
      end

      it 'shows empty state when there are no expiring accreditations' do
        non_expiring_registrar = create(:registrar, name: 'Non Expiring Ltd', accreditation_expire_date: 30.days.from_now)
        non_expiring_user = create(:user, registrar: non_expiring_registrar)
        create(:test_attempt, user: non_expiring_user, test: test, passed: true, created_at: 2.days.ago)

        get admin_dashboard_path

        expect(assigns(:expiring_accreditations)).to be_empty
        expect(response.body).to include(I18n.t('admin.dashboard.no_expiring_accreditations'))
      end
    end

    it 'redirects to root path when user is not admin' do
      sign_out :user
      sign_in(create(:user), scope: :user)
      get admin_dashboard_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
    end
  end
end
