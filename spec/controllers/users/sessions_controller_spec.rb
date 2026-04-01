require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  include Devise::Test::ControllerHelpers

  routes { Rails.application.routes }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    allow(controller).to receive(:configure_permitted_parameters).and_return(true)
    allow(controller).to receive(:assert_is_devise_resource!).and_return(true)
    allow(controller).to receive(:verify_signed_out_user).and_return(true)
  end

  describe 'DELETE #destroy' do
    it 'clears auth token from session' do
      session[:auth_token] = 'registry-token'

      delete :destroy, params: { locale: I18n.default_locale }

      expect(session[:auth_token]).to be_nil
      expect(response).to redirect_to(new_user_session_path(locale: I18n.default_locale))
    end
  end
end
