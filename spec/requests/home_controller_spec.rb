require 'rails_helper'

RSpec.describe 'HomeController', type: :request do
  describe 'GET /' do
    context 'as regular user' do
      let(:user) { create(:user, registrar_accreditation_expire_date: 10.days.from_now) }
      let(:test_record) { create(:test, :practical, time_limit_minutes: 60) }

      before { sign_in(user) }

      it 'renders dashboard and assigns expected instance variables' do
        in_progress = create(:test_attempt, user: user, test: test_record, started_at: 10.minutes.ago, completed_at: nil, created_at: 3.days.ago)
        not_started = create(:test_attempt, user: user, test: test_record, started_at: nil, completed_at: nil, created_at: 2.days.ago)
        _expired = create(:test_attempt, user: user, test: test_record, started_at: 2.hours.ago, completed_at: nil, created_at: 1.day.ago)

        completed_older = create(:test_attempt, :completed, user: user, test: test_record, created_at: 6.days.ago)
        completed_newer = create(:test_attempt, :completed, user: user, test: test_record, created_at: 1.hour.ago)

        get root_path

        expect(response).to have_http_status(:ok)
        expect(assigns(:assigned_tests)).to include(in_progress, not_started)
        expect(assigns(:assigned_tests)).not_to include(completed_newer)
        expect(assigns(:assigned_tests).map(&:id)).not_to include(_expired.id)

        expect(assigns(:completed_tests)).to include(completed_newer, completed_older)
        expect(assigns(:completed_tests).first).to eq(completed_newer)
        expect(assigns(:test_statistics)).to eq(user.test_statistics)

        expect(assigns(:accreditation_expiry_date)).to eq(user.registrar_accreditation_expire_date)
        expect(assigns(:accreditation_expires_soon)).to eq(user.registrar_accreditation_expires_soon?)
        expect(assigns(:days_until_expiry)).to eq(user.days_until_registrar_accreditation_expiry)
      end

      it 'limits completed tests to 5 items' do
        create_list(:test_attempt, 6, :completed, user: user, test: test_record)

        get root_path

        expect(assigns(:completed_tests).size).to eq(5)
      end
    end

    context 'as admin user' do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin, scope: :user) }

      it 'redirects to admin dashboard with access denied alert' do
        get root_path

        expect(response).to redirect_to(admin_dashboard_path)
        expect(flash[:alert]).to eq(I18n.t(:access_denied_admin))
      end
    end
  end
end
