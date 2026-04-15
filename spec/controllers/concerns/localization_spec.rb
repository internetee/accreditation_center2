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

    it 'reuses locale from cookie when locale param is not provided' do
      request.cookies[:locale] = 'en'

      get :index

      expect(response).to have_http_status(:ok)
      expect(I18n.locale).to eq(:en)
      expect(controller.instance_variable_get(:@pagy_locale)).to eq('en')
    end

    it 'does not overwrite existing locale cookie when locale param is blank' do
      request.cookies[:locale] = 'et'

      get :index, params: { locale: '' }

      expect(response).to have_http_status(:ok)
      expect(cookies[:locale]).to eq('et')
      expect(I18n.locale).to eq(:et)
    end

    it 'logs and falls back when no locale is present at all' do
      expect(controller.logger).to receive(:error).with(a_string_including(I18n.t(:no_translation)))

      get :index

      expect(response).to have_http_status(:ok)
      expect(I18n.locale).to eq(I18n.default_locale)
      expect(controller.instance_variable_get(:@pagy_locale)).to eq(I18n.default_locale.to_s)
    end

    it 'keeps invalid locale in cookie but falls back to default locale' do
      expect(controller.logger).to receive(:error).with("xx #{I18n.t(:no_translation)}")

      get :index, params: { locale: 'xx' }

      expect(response).to have_http_status(:ok)
      expect(cookies[:locale]).to eq('xx')
      expect(I18n.locale).to eq(I18n.default_locale)
    end
  end

  describe '#default_url_options' do
    it 'returns current locale in url options' do
      get :index, params: { locale: 'et' }

      expect(controller.send(:default_url_options)).to eq(locale: :et)
    end
  end
end
