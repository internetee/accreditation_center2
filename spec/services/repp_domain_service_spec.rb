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

    # Mock ApiConnector to avoid actual HTTP calls
    allow_any_instance_of(ApiConnector).to receive(:build_connection).and_return(double('connection'))
    allow_any_instance_of(described_class).to receive(:make_request).and_return(
      {
        success: true,
        data: {},
        message: 'Success'
      }
    )
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
      expect(service).to receive(:make_request).with(
        :post,
        api_url,
        hash_including(
          headers: headers,
          body: expected_body
        )
      ).and_return({ success: true, data: {}, message: 'Success' })

      service.create_domain(params)
    end

    it 'returns error response when request fails' do
      error_response = { success: false, message: 'Domain already exists', data: nil }
      allow(service).to receive(:make_request).and_return(error_response)

      result = service.create_domain(params)
      expect(result).to eq(error_response)
    end

    context 'when request succeeds' do
      it 'returns symbolized data from hash response' do
        response = {
          success: true,
          data: {
            'domain' => {
              'name' => 'example.ee',
              'status' => 'ok'
            }
          }
        }

        allow(service).to receive(:make_request).and_return(response)

        result = service.create_domain(params)
        expect(result).to eq(domain: { name: 'example.ee', status: 'ok' })
      end

      it 'parses JSON string and returns symbolized data' do
        json_payload = {
          domain: {
            name: 'example.ee',
            registrant: 'ORG123'
          }
        }.to_json

        allow(service).to receive(:make_request).and_return(
          success: true,
          data: json_payload
        )

        result = service.create_domain(params)
        expect(result).to eq(domain: { name: 'example.ee', registrant: 'ORG123' })
      end

      it 'extracts data from nested data key' do
        response = {
          success: true,
          data: {
            'data' => {
              'domain' => {
                'name' => 'example.ee',
                'status' => 'active'
              }
            }
          }
        }

        allow(service).to receive(:make_request).and_return(response)

        result = service.create_domain(params)
        expect(result).to eq(domain: { name: 'example.ee', status: 'active' })
      end

      it 'handles response without nested data key' do
        response = {
          success: true,
          data: {
            'name' => 'example.ee',
            'status' => 'pending'
          }
        }

        allow(service).to receive(:make_request).and_return(response)

        result = service.create_domain(params)
        expect(result).to eq(name: 'example.ee', status: 'pending')
      end
    end
  end
end
