require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  include Devise::Test::ControllerHelpers

  routes { Rails.application.routes }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    allow(controller).to receive(:configure_permitted_parameters).and_return(true)
    allow(controller).to receive(:assert_is_devise_resource!).and_return(true)
  end

  describe 'GET #oidc' do
    it 'redirects to login when omniauth payload is missing' do
      get :oidc

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be_present
    end

    it 'redirects admin identity to admin login and skips omniauth user creation' do
      admin = create(:user, :admin,
                     provider: 'oidc',
                     uid: 'EE39901012239',
                     password: 'AdminPass123!',
                     password_confirmation: 'AdminPass123!')
      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: admin.uid, info: { name: admin.name, email: admin.email })
      request.env['omniauth.auth'] = auth

      allow(controller).to receive(:api_authenticate_user)

      get :oidc

      expect(controller).not_to have_received(:api_authenticate_user)
      expect(response).to redirect_to(new_admin_session_path(locale: I18n.default_locale))
    end

    it 'authenticates non-admin via oidc service and stores auth token' do
      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: 'EE49901012239', info: { name: 'Normal User', email: 'u@test' })
      request.env['omniauth.auth'] = auth

      service = instance_double(OidcAuthenticationService)
      allow(OidcAuthenticationService).to receive(:new).with(uid: 'EE49901012239').and_return(service)
      allow(service).to receive(:authenticate_user).and_return(
        success: true,
        auth_token: 'registry-token',
        username: 'user1',
        registrar_email: 'u@test',
        registrar_name: 'Registrar Ltd',
        accreditation_date: Date.new(2026, 1, 1),
        accreditation_expire_date: Date.new(2027, 1, 1)
      )
      allow(controller).to receive(:sign_in)
      allow(controller).to receive(:assign_test_attempts)

      get :oidc

      created_user = User.find_by(provider: 'oidc', uid: 'EE49901012239')
      expect(created_user).to be_present
      expect(session[:auth_token]).to eq('registry-token')
      expect(controller).to have_received(:sign_in).with(created_user)
      expect(response).to redirect_to(root_path(locale: I18n.default_locale))
      expect(created_user.email).to eq('u@test')
      expect(created_user.name).to eq('Normal User')
      expect(created_user.username).to eq('user1')
      expect(created_user.registrar).to be_present
      expect(created_user.registrar.name).to eq('Registrar Ltd')
      expect(created_user.registrar.email).to eq('u@test')
      expect(created_user.registrar.accreditation_date.to_date).to eq(Date.new(2026, 1, 1))
      expect(created_user.registrar.accreditation_expire_date.to_date).to eq(Date.new(2027, 1, 1))
    end

    it 'falls back username to uid when api response has no username' do
      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: 'EE50001012239', info: { name: 'Fallback User', email: 'fallback@test' })
      request.env['omniauth.auth'] = auth

      service = instance_double(OidcAuthenticationService)
      allow(OidcAuthenticationService).to receive(:new).with(uid: 'EE50001012239').and_return(service)
      allow(service).to receive(:authenticate_user).and_return(
        success: true,
        auth_token: 'registry-token',
        username: nil,
        registrar_email: 'fallback@test',
        registrar_name: 'Registrar Ltd',
        accreditation_date: Date.new(2026, 1, 1),
        accreditation_expire_date: Date.new(2027, 1, 1)
      )
      allow(controller).to receive(:sign_in)
      allow(controller).to receive(:assign_test_attempts)

      get :oidc

      created_user = User.find_by(provider: 'oidc', uid: 'EE50001012239')
      expect(created_user).to be_present
      expect(created_user.username).to eq('EE50001012239')
    end

    it 'does not re-save existing user when oidc and api data are unchanged' do
      registrar = create(
        :registrar,
        name: 'Registrar Ltd',
        email: 'u@test',
        accreditation_date: Date.new(2026, 1, 1),
        accreditation_expire_date: Date.new(2027, 1, 1)
      )
      existing_user = create(
        :user,
        provider: 'oidc',
        uid: 'EE50101012239',
        email: 'u@test',
        name: 'Normal User',
        username: 'user1',
        registrar: registrar
      )
      previous_updated_at = existing_user.updated_at
      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: existing_user.uid, info: { name: existing_user.name, email: existing_user.email })
      request.env['omniauth.auth'] = auth

      service = instance_double(OidcAuthenticationService)
      allow(OidcAuthenticationService).to receive(:new).with(uid: existing_user.uid).and_return(service)
      allow(service).to receive(:authenticate_user).and_return(
        success: true,
        auth_token: 'registry-token',
        username: 'user1',
        registrar_email: 'u@test',
        registrar_name: 'Registrar Ltd',
        accreditation_date: Date.new(2026, 1, 1),
        accreditation_expire_date: Date.new(2027, 1, 1)
      )
      allow(controller).to receive(:sign_in)
      allow(controller).to receive(:assign_test_attempts)

      expect do
        get :oidc
      end.not_to change(User, :count)

      expect(existing_user.reload.updated_at).to eq(previous_updated_at)
      expect(controller).to have_received(:sign_in).with(existing_user)
      expect(response).to redirect_to(root_path(locale: I18n.default_locale))
    end

    it 'does not persist user when oidc service authentication fails' do
      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: 'EE59901012239', info: { name: 'Failed User', email: 'failed@test' })
      request.env['omniauth.auth'] = auth

      service = instance_double(OidcAuthenticationService)
      allow(OidcAuthenticationService).to receive(:new).with(uid: 'EE59901012239').and_return(service)
      allow(service).to receive(:authenticate_user).and_return(
        success: false,
        message: 'Invalid credentials'
      )
      allow(controller).to receive(:sign_in)

      expect do
        get :oidc
      end.not_to change(User, :count)

      expect(controller).not_to have_received(:sign_in)
      expect(User.find_by(provider: 'oidc', uid: 'EE59901012239')).to be_nil
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq('Invalid credentials')
    end

    it 'does not persist user when oidc user persistence is invalid' do
      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: 'EE69901012239', info: { name: 'Conflicted User', email: 'conflict@test' })
      request.env['omniauth.auth'] = auth
      create(:user, username: 'dup-username')

      service = instance_double(OidcAuthenticationService)
      allow(OidcAuthenticationService).to receive(:new).with(uid: 'EE69901012239').and_return(service)
      allow(service).to receive(:authenticate_user).and_return(
        success: true,
        auth_token: 'registry-token',
        username: 'dup-username',
        registrar_email: 'conflict@test',
        registrar_name: 'Registrar Ltd',
        accreditation_date: Date.new(2026, 1, 1),
        accreditation_expire_date: Date.new(2027, 1, 1)
      )
      allow(controller).to receive(:sign_in)

      expect do
        get :oidc
      end.not_to change(User, :count)

      expect(controller).not_to have_received(:sign_in)
      expect(User.find_by(provider: 'oidc', uid: 'EE69901012239')).to be_nil
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('Username has already been taken')
    end

    it 'redirects immediately when callback belongs to current user' do
      user = create(:user, provider: 'oidc', uid: 'EE77701012239')
      sign_in(user, scope: :user)
      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: user.uid, info: { name: user.name, email: user.email })
      request.env['omniauth.auth'] = auth

      allow(controller).to receive(:api_authenticate_user)

      get :oidc

      expect(controller).not_to have_received(:api_authenticate_user)
      expect(response).to redirect_to(root_path(locale: I18n.default_locale))
    end

    it 'signs out current user when callback belongs to different user' do
      current_user = create(:user, provider: 'oidc', uid: 'EE11101012239')
      sign_in(current_user, scope: :user)

      auth = OmniAuth::AuthHash.new(provider: :oidc, uid: 'EE22201012239', info: { name: 'Other User', email: 'other@test' })
      request.env['omniauth.auth'] = auth

      allow(controller).to receive(:sign_out)
      allow(controller).to receive(:api_authenticate_user) do
        controller.redirect_to(root_path(locale: I18n.default_locale))
      end

      get :oidc

      expect(controller).to have_received(:sign_out).with(current_user)
      expect(controller).to have_received(:api_authenticate_user).with(auth)
    end
  end
end
