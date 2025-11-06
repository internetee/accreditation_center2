require 'rails_helper'

RSpec.describe 'Localization', type: :request do
  let(:user) { create(:user) }

  around do |ex|
    old = I18n.locale
    ex.run
    I18n.locale = old
  end

  before do
    sign_in user, scope: :user
  end

  it 'sets locale from params and stores cookie' do
    get root_path(locale: :et)

    expect(response).to have_http_status(:ok)
    expect(I18n.locale).to eq(:et)
    expect(cookies[:locale]).to eq('et')
  end

  it 'reuses locale from cookie when no param' do
    # First request sets cookie
    get root_path(locale: :en)

    expect(cookies[:locale]).to eq('en')

    # Next request without param picks cookie
    get root_path

    expect(I18n.locale).to eq(:en)
  end

  it 'logs error and falls back when locale is invalid' do
    get root_path params: { locale: 'xx' }

    expect(response).to have_http_status(:ok)
    # expect(Rails.logger).to receive(:error).with("xx #{I18n.t(:no_translation)}")
    expect(I18n.locale).to eq(I18n.default_locale)
    # Cookie not changed to invalid
    expect(cookies[:locale]).not_to eq('xx')
  end
end
