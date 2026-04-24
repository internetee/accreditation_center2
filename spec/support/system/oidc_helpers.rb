module SystemOidcHelpers
  def login_with_oidc(button_text: I18n.t('users.sessions.new.login_with_id'))
    visit new_user_session_path
    click_button button_text
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

  def stub_oidc_api_auth(email:, registrar_name: 'Registrar Ltd', accreditation_date: Date.current, accreditation_expire_date: 1.year.from_now.to_date)
    service = instance_double(OidcAuthenticationService)
    allow(OidcAuthenticationService).to receive(:new).and_return(service)
    allow(service).to receive(:authenticate_user).and_return(
      success: true,
      auth_token: 'registry-token',
      registrar_email: email,
      registrar_name: registrar_name,
      accreditation_date: accreditation_date,
      accreditation_expire_date: accreditation_expire_date
    )
  end
end
