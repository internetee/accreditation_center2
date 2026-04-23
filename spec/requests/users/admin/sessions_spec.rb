require 'rails_helper'

RSpec.describe 'Users::Admin::Sessions', type: :request do
  describe 'POST /admin/login' do
    let(:password) { 'AdminPass123!' }
    let(:admin) do
      create(:user, :admin,
             password: password,
             password_confirmation: password)
    end

    it 'signs in admin with valid credentials' do
      post admin_session_path, params: {
        user: {
          email: admin.email,
          password: password
        }
      }

      expect(response).to redirect_to(admin_dashboard_path)
      expect(flash[:notice]).to eq(I18n.t('devise.sessions.signed_in'))
    end

    it 'rejects admin login with invalid password' do
      post admin_session_path, params: {
        user: {
          email: admin.email,
          password: 'WrongPass123!'
        }
      }

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include(I18n.t('devise.failure.not_found_in_database'))
    end

    it 'rejects non-admin user credentials' do
      user = create(:user, password: 'UserPass123!', password_confirmation: 'UserPass123!')

      post admin_session_path, params: {
        user: {
          email: user.email,
          password: 'UserPass123!'
        }
      }

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include(I18n.t('devise.failure.not_found_in_database'))
    end
  end
end
