require 'rails_helper'

RSpec.describe ReppDomainService do
  let(:base_url) { 'https://repp.example.com' }
  let(:endpoint) { '/repp/v1/domains' }
  let(:api_url) { base_url + endpoint }
  let(:bot_username) { 'accr_bot' }
  let(:bot_password) { 'secret_password' }

  before do
    ENV['REPP_BASE_URL'] = base_url
    ENV['REPP_CREATE_DOMAIN'] = endpoint
    ENV['ACCR_BOT_USERNAME'] = bot_username
    ENV['ACCR_BOT_PASSWORD'] = bot_password
    ENV['CLIENT_BOT_CERTS_PATH'] = '/path/to/cert'
    ENV['CLIENT_BOT_KEY_PATH'] = '/path/to/key'
  end

  describe '#initialize' do
    it 'sets the API URL correctly' do
      service = described_class.new
      expect(service.instance_variable_get(:@api_url_create)).to eq(api_url)
    end

    it 'calls super to initialize BotAuthService' do
      expect_any_instance_of(BotAuthService).to receive(:initialize)
      described_class.new
    end
  end

  describe '#create_domain' do
    let(:service) { described_class.new }
    let(:headers) { service.instance_variable_get(:@headers) }
    let(:params) do
      {
        name: 'example.ee',
        registrant: 'ORG123',
        period: 1,
        period_unit: 'y'
      }
    end
    let(:expected_body) { { domain: params }.to_json }

    it 'makes a POST request with correct body' do
      stub_request(:post, api_url)
        .with(headers: headers, body: expected_body)
        .and_return(
          status: 200,
          body: {
            data: {
              domain: { name: 'example.ee', transfer_code: '1234567890', id: '1234567890' }
            }
          }.to_json
        )

      expect(service.create_domain(params)).to include(
        domain: { name: 'example.ee', transfer_code: '1234567890', id: '1234567890' }
      )
    end

    it 'returns domain not found error on domain not created' do
      stub_request(:post, api_url)
        .with(headers: headers, body: expected_body)
        .and_return(
          status: 400,
          body: { code: 2104, message: 'Active price missing for this operation!' }.to_json
        )

      expect(service.create_domain(params)).to include(
        success: false,
        data: nil,
        message: I18n.t('errors.unexpected_response')
      )
    end

    it 'returns failure payload on invalid credentials' do
      stub_request(:post, api_url)
        .with(headers: headers, body: expected_body)
        .and_return(
          status: 401,
          body: { code: 2202, message: 'Invalid authorization information' }.to_json
        )

      expect(service.create_domain(params)).to include(
        success: false,
        data: nil,
        message: I18n.t('errors.invalid_credentials')
      )
    end

    it 'returns invalid data format error on invalid data format' do
      stub_request(:post, api_url)
        .with(headers: headers, body: expected_body)
        .and_return(
          status: 200,
          body: 'invalid data format'
        )

      expect(service.create_domain(params)).to include(
        success: false,
        data: nil,
        message: I18n.t('errors.unexpected_response')
      )
    end
  end
end
