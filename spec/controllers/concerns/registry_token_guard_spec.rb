require 'rails_helper'

RSpec.describe RegistryTokenGuard, type: :controller do
  controller(ActionController::Base) do
    include RegistryTokenGuard
    before_action :ensure_registry_token!

    def index
      render plain: 'ok'
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe '#ensure_registry_token!' do
    it 'does nothing in test environment even without token' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('ok')
    end

    context 'when not in test environment' do
      let(:user) { create(:user) }

      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'redirects to login when token is missing' do
        expect(controller).to receive(:sign_out).with(user)

        get :index

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq('Your API session expired. Please sign in again.')
      end

      it 'allows request when token is present and expiry is not tracked' do
        session[:auth_token] = 'token-123'

        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'allows request when token is present and expiry time is in the future' do
        session[:auth_token] = 'token-123'
        session[:auth_token_expires_at] = 2.hours.from_now

        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'redirects when token is present and expiry string is in the past' do
        session[:auth_token] = 'token-123'
        session[:auth_token_expires_at] = 1.hour.ago.iso8601
        expect(controller).to receive(:sign_out).with(user)

        get :index

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects when token is present but expiry string is invalid' do
        session[:auth_token] = 'token-123'
        session[:auth_token_expires_at] = 'not-a-time'
        expect(controller).to receive(:sign_out).with(user)

        get :index

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
