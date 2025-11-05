require 'rails_helper'

RSpec.describe Users::SessionsController, type: :request do
  # Shared defaults for API auth scenarios
  let(:username) { 'registrar1' }
  let(:password) { 'Secret123' }
  let(:params)   { { user: { username: username, password: password } } }

  # Helpers to DRY stubs for AuthenticationService and ApiTokenService
  def stub_successful_api_auth(username:, password:)
    allow(AuthenticationService).to receive(:new)
      .with(username: username, password: password)
      .and_return(
        double(
          authenticate_user: {
            success: true,
            username: username,
            registrar_email: 'r@example.com',
            registrar_name: 'Registrar Ltd',
            accreditation_date: Date.current,
            accreditation_expire_date: 1.year.from_now.to_date
          }
        )
      )
    token_service_double = double
    allow(ApiTokenService).to receive(:new)
      .with(username: username, password: password).and_return(token_service_double)
    allow(token_service_double).to receive(:generate).and_return('jwt-token')
    token_service_double
  end

  def stub_failed_api_auth(username:, password:)
    allow(AuthenticationService).to receive(:new)
      .with(username: username, password: password)
      .and_return(
        double(
          authenticate_user: {
            success: false,
            message: 'Invalid authorization information'
          }
        )
      )
  end

  describe 'POST /users/sign_in' do
    context 'with blank credentials' do
      let(:username) { '' }
      let(:password) { '' }

      it 'renders new with unauthorized and flash' do
        post user_session_path, params: params

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include(I18n.t('devise.failure.invalid', authentication_keys: 'username'))
      end
    end

    context 'admin local auth' do
      let(:password) { 'Secret123' }
      let(:username) { 'adminuser' }
      let!(:admin) { create(:user, username: username, password: password, password_confirmation: password, role: 'admin') }

      it 'signs in and redirects to admin dashboard' do
        post user_session_path, params: params

        expect(response).to redirect_to(admin_dashboard_path)
        follow_redirect!
        expect(controller.current_user).to eq(admin)
        expect(flash[:notice]).to eq(I18n.t('devise.sessions.signed_in'))
      end
    end

    context 'API auth success (non-admin)' do
      it 'creates/fetches user, sets session token, redirects root' do
        stub_successful_api_auth(username: username, password: password)

        post user_session_path, params: params

        expect(response).to redirect_to(root_path)
        expect(session[:auth_token]).to eq('jwt-token')
        user = User.find_by(username: username)
        expect(user.email).to eq('r@example.com')
        expect(user.registrar_name).to eq('Registrar Ltd')
        expect(user.accreditation_date.to_date).to eq(Date.current)
        expect(user.accreditation_expire_date.to_date).to eq(1.year.from_now.to_date)
      end
    end

    context 'API auth failure' do
      let(:password) { 'wrong' }

      it 'renders new with unauthorized and error from service' do
        stub_failed_api_auth(username: username, password: password)

        post user_session_path, params: params

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Invalid authorization information')
        expect(session[:auth_token]).to be_nil
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    it 'signs in via POST and then signs out' do
      stub_successful_api_auth(username: username, password: password)
      post user_session_path, params: params

      expect(response).to redirect_to(root_path)
      expect(session[:auth_token]).to eq('jwt-token')
      expect(controller.current_user).to eq(User.find_by(username: username))

      delete destroy_user_session_path
      expect(response).to redirect_to(root_path(locale: I18n.locale))
      expect(session[:auth_token]).to be_nil

      # Optional: verify access to an authenticated route now redirects to sign in
      get admin_dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
