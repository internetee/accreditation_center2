require 'rails_helper'

RSpec.describe InvoiceService do
  let(:base_url) { 'https://api.example.com' }
  let(:endpoint) { '/repp/v1/invoices' }
  let(:token) { 'invoice-token' }
  let(:connection) { instance_double(Faraday::Connection) }

  before do
    ENV['BASE_URL'] = base_url
    ENV['GET_INVOICES'] = endpoint
    allow_any_instance_of(ApiConnector).to receive(:build_connection).and_return(connection)
  end

  describe '#initialize' do
    it 'configures API url and headers' do
      service = described_class.new(token: token)

      expect(service.instance_variable_get(:@api_url)).to eq("#{base_url}#{endpoint}")
      expect(service.instance_variable_get(:@headers)).to eq('Authorization' => "Basic #{token}")
    end
  end

  describe '#cancelled_invoices' do
    let(:service) { described_class.new(token: token) }
    let(:headers) { service.instance_variable_get(:@headers) }

    it 'returns empty array when request fails' do
      allow(service).to receive(:make_request).and_return(success: false, message: 'error', data: nil)

      expect(service.cancelled_invoices).to eq([])
    end

    it 'symbolizes invoices from hash response' do
      response = {
        success: true,
        data: {
          'invoices' => [
            { 'number' => 'INV-1', 'status' => 'cancelled' }
          ]
        }
      }

      expect(service).to receive(:make_request)
        .with(:get, "#{base_url}#{endpoint}", { headers: headers })
        .and_return(response)

      result = service.cancelled_invoices

      expect(result).to eq([{ number: 'INV-1', status: 'cancelled' }])
    end

    it 'symbolizes invoices from JSON string response' do
      payload = {
        invoices: [
          { number: 'INV-2', status: 'cancelled' }
        ]
      }.to_json

      allow(service).to receive(:make_request).and_return(success: true, data: payload)

      result = service.cancelled_invoices

      expect(result).to eq([{ number: 'INV-2', status: 'cancelled' }])
    end

    it 'symbolizes invoices when response is already an array' do
      response = {
        success: true,
        data: [
          { 'number' => 'INV-3', 'status' => 'cancelled' }
        ]
      }

      allow(service).to receive(:make_request).and_return(response)

      expect(service.cancelled_invoices).to eq([{ number: 'INV-3', status: 'cancelled' }])
    end

    it 'handles nil invoices gracefully' do
      allow(service).to receive(:make_request).and_return(success: true, data: nil)

      expect(service.cancelled_invoices).to eq([])
    end
  end
end
