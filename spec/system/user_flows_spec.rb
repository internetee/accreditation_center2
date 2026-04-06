require 'rails_helper'

RSpec.describe 'User flows', type: :system do
  before { driven_by(:rack_test) }

  around do |example|
    OmniAuth.config.test_mode = true
    example.run
  ensure
    OmniAuth.config.mock_auth[:oidc] = nil
    OmniAuth.config.test_mode = false
  end

  let(:login_button_text) { I18n.t('users.sessions.new.login_with_id') }

  it 'redirects admin oidc login to admin password login' do
    admin = create(:user, :admin, provider: 'oidc', uid: 'EE39901012239')
    mock_oidc_auth(uid: admin.uid, email: admin.email, name: admin.name)

    login_with_oidc

    expect(page).to have_current_path(new_admin_session_path(locale: I18n.default_locale))
  end

  it 'logs in non-admin via oidc + api auth' do
    mock_oidc_auth(uid: 'EE49901012239', email: 'user@example.test', given_name: 'Test', family_name: 'User')
    stub_oidc_api_auth(email: 'user@example.test')
    login_with_oidc

    expect(page).to have_current_path(root_path(locale: I18n.default_locale))
  end

  it 'logs out and returns to login page for normal user' do
    user = create(:user, provider: 'oidc', uid: 'EE39901012239')
    mock_oidc_auth(uid: user.uid, email: user.email, name: user.name)
    stub_oidc_api_auth(email: user.email)
    login_with_oidc
    expect(page).to have_current_path(root_path(locale: I18n.default_locale))

    within(all('nav.menu--user').first) do
      click_button I18n.t('devise.sessions.sign_out')
    end

    expect(page).to have_current_path(new_user_session_path(locale: I18n.default_locale))
    expect(page).to have_button(login_button_text)
  end

  it 'blocks normal user from admin dashboard path' do
    user = create(:user, provider: 'oidc', uid: 'EE59901012239')
    mock_oidc_auth(uid: user.uid, email: user.email, name: user.name)
    stub_oidc_api_auth(email: user.email)
    login_with_oidc
    expect(page).to have_current_path(root_path(locale: I18n.default_locale))

    visit admin_dashboard_path(locale: I18n.default_locale)
    expect(page).to have_current_path(root_path(locale: I18n.default_locale))
    expect(page).to have_content('Access denied. Admin privileges required.')
  end

  def login_with_oidc
    visit new_user_session_path
    click_button login_button_text
  end

  def mock_oidc_auth(uid:, email:, name: nil, given_name: nil, family_name: nil)
    info = { email: email }
    info[:name] = name if name
    info[:given_name] = given_name if given_name
    info[:family_name] = family_name if family_name

    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
      provider: :oidc,
      uid: uid,
      info: info
    )
  end

  def stub_oidc_api_auth(email:)
    service = instance_double(OidcAuthenticationService)
    allow(OidcAuthenticationService).to receive(:new).and_return(service)
    allow(service).to receive(:authenticate_user).and_return(
      success: true,
      auth_token: 'registry-token',
      registrar_email: email,
      registrar_name: 'Registrar Ltd',
      accreditation_date: Date.current,
      accreditation_expire_date: 1.year.from_now.to_date
    )
  end
end
