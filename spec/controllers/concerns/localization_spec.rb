require 'rails_helper'

RSpec.describe Localization, type: :controller do
  controller(ActionController::Base) do
    include Localization

    def index
      render plain: 'ok'
    end
  end

  around do |example|
    previous_locale = I18n.locale
    example.run
    I18n.locale = previous_locale
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe '#switch_locale' do
    it 'sets locale from params and stores it in cookies' do
      get :index, params: { locale: 'et' }

      expect(response).to have_http_status(:ok)
      expect(I18n.locale).to eq(:et)
      expect(cookies[:locale]).to eq('et')
      expect(controller.instance_variable_get(:@pagy_locale)).to eq('et')
    end

    it 'logs invalid locale from cookie and falls back to default locale' do
      request.cookies[:locale] = 'xx'
      expect(controller.logger).to receive(:error).with("xx #{I18n.t(:no_translation)}")

      get :index

      expect(response).to have_http_status(:ok)
      expect(I18n.locale).to eq(I18n.default_locale)
      expect(controller.instance_variable_get(:@pagy_locale)).to eq(I18n.default_locale.to_s)
    end
  end

  describe '#default_url_options' do
    it 'returns current locale in url options' do
      get :index, params: { locale: 'et' }

      expect(controller.send(:default_url_options)).to eq(locale: :et)
    end
  end
end
