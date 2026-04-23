require 'rails_helper'

RSpec.describe OidcAuthenticationService do
  let(:base_url) { 'https://registry.test' }
  let(:auth_path) { '/repp/v1/registrar/auth/tara_callback' }

  before do
    ENV['REPP_BASE_URL'] = base_url
    ENV['REPP_AUTH_TOKEN_URL'] = auth_path
    ENV['WEBCLIENT_CERT_PATH'] = '/tmp/webclient.crt.pem'
    ENV['WEBCLIENT_KEY_PATH'] = '/tmp/webclient.key.pem'
  end

  describe '#initialize' do
    it 'raises when uid is blank' do
      expect { described_class.new(uid: nil) }.to raise_error(ArgumentError, 'OIDC uid is required')
    end

    it 'sets API url from env vars' do
      service = described_class.new(uid: 'EE39901012239')

      expect(service.instance_variable_get(:@api_url)).to eq("#{base_url}#{auth_path}")
    end
  end

  describe '#authenticate_user' do
    it 'returns mapped success payload for valid API response' do
      service = described_class.new(uid: 'EE39901012239')
      api_response = {
        'id' => 1,
        'token' => 'registry-token',
        'username' => 'registrar1',
        'roles' => %w[user],
        'registrar_name' => 'Registrar Ltd',
        'registrar_reg_no' => '12345',
        'registrar_email' => 'registrar@example.test',
        'accreditation_date' => Date.current,
        'accreditation_expire_date' => 1.year.from_now.to_date
      }

      expect(service).to receive(:make_request).with(
        :post,
        "#{base_url}#{auth_path}",
        {
          headers: {
            'Content-Type' => 'application/json',
            'Requester' => 'webclient'
          },
          body: { auth: { uid: 'EE39901012239' } }.to_json
        }
      ).and_return(success: true, data: api_response, message: 'ok')

      result = service.authenticate_user

      expect(result).to include(
        success: true,
        auth_token: 'registry-token',
        user_id: 1,
        username: 'registrar1',
        roles: %w[user],
        registrar_name: 'Registrar Ltd',
        registrar_reg_no: '12345',
        registrar_email: 'registrar@example.test'
      )
    end

    it 'passes through error response when request fails' do
      service = described_class.new(uid: 'EE39901012239')
      expected = { success: false, message: 'Invalid authorization information', data: nil }
      allow(service).to receive(:make_request).and_return(expected)

      expect(service.authenticate_user).to eq(expected)
    end

    it 'returns unexpected_response when success payload is malformed' do
      service = described_class.new(uid: 'EE39901012239')
      allow(service).to receive(:make_request).and_return(success: true, data: { 'token' => 't' }, message: 'ok')

      expect(service.authenticate_user).to eq(
        success: false,
        message: I18n.t('errors.unexpected_response'),
        data: nil
      )
    end
  end
end
