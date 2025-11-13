require 'rails_helper'

RSpec.describe DomainService do
  let(:base_url) { 'https://api.example.com' }
  let(:endpoint) { '/repp/v1/domains' }
  let(:token) { 'domain-token' }
  let(:connection) { instance_double(Faraday::Connection) }

  before do
    ENV['BASE_URL'] = base_url
    ENV['GET_DOMAIN_INFO'] = endpoint
    allow_any_instance_of(ApiConnector).to receive(:build_connection).and_return(connection)
  end

  describe '#initialize' do
    it 'configures API url and headers' do
      service = described_class.new(token: token)

      expect(service.instance_variable_get(:@api_url_info)).to eq("#{base_url}#{endpoint}")
      expect(service.instance_variable_get(:@headers)).to eq('Authorization' => "Basic #{token}")
    end
  end

  describe '#domain_info' do
    let(:service) { described_class.new(token: token) }
    let(:headers) { service.instance_variable_get(:@headers) }
    let(:url) { "#{base_url}#{endpoint}?name=example.ee" }

    it 'returns the response when request fails' do
      error_response = { success: false, message: 'Not found', data: nil }
      allow(service).to receive(:make_request).and_return(error_response)

      expect(service.domain_info(name: 'example.ee')).to eq(error_response)
    end

    it 'symbolizes hash payload from API directly' do
      response = {
        success: true,
        data: { 'domain' => { 'name' => 'example.ee', 'status' => 'ok' } }
      }

      expect(service).to receive(:make_request).with(:get, url, { headers: headers }).and_return(response)

      result = service.domain_info(name: 'example.ee')

      expect(result).to eq(name: 'example.ee', status: 'ok')
    end

    it 'symbolizes JSON string payload from API' do
      payload = {
        domain: {
          name: 'example.ee',
          registrar: 'Example Registrar'
        }
      }.to_json

      allow(service).to receive(:make_request).and_return(success: true, data: payload)

      result = service.domain_info(name: 'example.ee')

      expect(result).to eq(name: 'example.ee', registrar: 'Example Registrar')
    end

    it 'symbolizes payload without domain key' do
      response = {
        success: true,
        data: { 'name' => 'example.ee', 'status' => 'inactive' }
      }

      allow(service).to receive(:make_request).and_return(response)

      result = service.domain_info(name: 'example.ee')

      expect(result).to eq(name: 'example.ee', status: 'inactive')
    end

    it 'escapes domain name in query' do
      expect(service).to receive(:make_request)
        .with(:get, "#{base_url}#{endpoint}?name=example.ee%2Ftest", { headers: headers })
        .and_return(success: false, message: 'error', data: nil)

      service.domain_info(name: 'example.ee/test')
    end
  end
end
