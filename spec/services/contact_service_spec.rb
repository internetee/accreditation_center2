require 'rails_helper'

RSpec.describe ContactService do
  let(:base_url) { 'https://api.example.com' }
  let(:endpoint) { '/repp/v1/contacts' }
  let(:api_url) { base_url + endpoint }
  let(:token) { 'auth-token' }
  let(:connection) { instance_double(Faraday::Connection) }

  before do
    ENV['BASE_URL'] = base_url
    ENV['GET_CONTACT'] = endpoint
    allow_any_instance_of(ApiConnector).to receive(:build_connection).and_return(connection)
  end

  describe '#initialize' do
    it 'configures API url and delegates to ApiConnector' do
      service = described_class.new(token: token)

      expect(service.instance_variable_get(:@api_url)).to eq(api_url)
      expect(service.instance_variable_get(:@headers)).to eq('Authorization' => "Basic #{token}")
    end
  end

  describe '#contact_info' do
    let(:service) { described_class.new(token: token) }
    let(:headers) { service.instance_variable_get(:@headers) }

    it 'returns symbolized contact data when request succeeds with hash payload' do
      api_response = {
        success: true,
        data: { 'contact' => { 'name' => 'Alice', 'email' => 'alice@example.test' } }
      }

      expect(service).to receive(:make_request)
        .with(:get, "#{api_url}?id=ABC123", { headers: headers })
        .and_return(api_response)

      result = service.contact_info(id: 'ABC123')

      expect(result).to eq(name: 'Alice', email: 'alice@example.test')
    end

    it 'parses JSON string payload before symbolizing' do
      json_payload = {
        contact: {
          name: 'Bob',
          email: 'bob@example.test'
        }
      }.to_json

      allow(service).to receive(:make_request).and_return(
        success: true,
        data: json_payload
      )

      result = service.contact_info(id: 'DEF456')

      expect(result).to eq(name: 'Bob', email: 'bob@example.test')
    end

    it 'returns error response when request fails' do
      error_response = { success: false, message: 'Not found', data: nil }
      allow(service).to receive(:make_request).and_return(error_response)

      expect(service.contact_info(id: 'XYZ789')).to eq(error_response)
    end
  end
end
