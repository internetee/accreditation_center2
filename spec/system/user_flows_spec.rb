require 'rails_helper'

RSpec.describe 'User flows', type: :system do
  before { driven_by(:rack_test) }
  include_context 'with omniauth test mode'

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
    expect(Registrar.count).to eq(1)
    expect(Registrar.first.name).to eq('Registrar Ltd')
    expect(Registrar.first.email).to eq('user@example.test')
  end

  it 'reuses existing registrar when another user logs in with the same registrar' do
    existing_expire_date = 2.years.from_now.to_date
    existing_user = create(
      :user,
      registrar_name: 'Registrar Ltd',
      registrar_email: 'existing.registrar@example.test',
      registrar_accreditation_date: 1.year.ago.to_date,
      registrar_accreditation_expire_date: existing_expire_date
    )
    existing_registrar_id = existing_user.registrar_id

    mock_oidc_auth(uid: 'EE69901012239', email: 'second.user@example.test', given_name: 'Second', family_name: 'User')
    stub_oidc_api_auth(
      email: 'second.user@example.test',
      accreditation_date: Date.current,
      accreditation_expire_date: 3.months.from_now.to_date
    )

    login_with_oidc

    new_user = User.find_by(provider: 'oidc', uid: 'EE69901012239')
    existing_registrar = Registrar.find(existing_registrar_id)
    expect(new_user).to be_present
    expect(new_user.registrar_id).to eq(existing_registrar_id)
    expect(Registrar.count).to eq(1)
    expect(existing_registrar.users.count).to eq(2)
    expect(existing_registrar.accreditation_expire_date.to_date).to eq(existing_expire_date)
  end

  it 'creates a new registrar when another user logs in with a different registrar' do
    existing_user = create(:user, registrar_name: 'Registrar Ltd', registrar_email: 'existing.registrar@example.test')
    existing_registrar_id = existing_user.registrar_id

    mock_oidc_auth(uid: 'EE79901012239', email: 'other.registrar.user@example.test', given_name: 'Other', family_name: 'Registrar')
    stub_oidc_api_auth(email: 'other.registrar.user@example.test', registrar_name: 'Other Registrar Ltd')

    login_with_oidc

    new_user = User.find_by(provider: 'oidc', uid: 'EE79901012239')
    expect(new_user).to be_present
    expect(new_user.registrar.name).to eq('Other Registrar Ltd')
    expect(new_user.registrar_id).not_to eq(existing_registrar_id)
    expect(Registrar.count).to eq(2)
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
end
