require 'rails_helper'

RSpec.describe ApiConnector do
  let(:token_service) { instance_double(ApiTokenService, generate: 'encoded-token') }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:connector) { described_class.new(token: 'pre-generated-token') }

  before do
    allow(ApiTokenService).to receive(:new).and_return(token_service)
    allow(Faraday).to receive(:new).and_return(connection)
    allow(Rails.logger).to receive(:debug)
    allow(Rails.logger).to receive(:error)
  end

  describe '#initialize' do
    it 'builds an auth token when username/password provided' do
      expect(ApiTokenService).to receive(:new).with(username: 'user', password: 'secret').and_return(token_service)
      expect(token_service).to receive(:generate).and_return('encoded-token')

      connector = described_class.new(username: 'user', password: 'secret')

      expect(connector.instance_variable_get(:@headers)).to eq('Authorization' => 'Basic encoded-token')
    end

    it 'uses provided token without calling ApiTokenService' do
      expect(ApiTokenService).not_to receive(:new)

      described_class.new(token: 'token-from-env')
    end
  end

  describe '#make_request' do
    let(:url) { '/api/resource' }

    before do
      allow(connection).to receive(:send)
    end

    it 'returns error when url is nil' do
      connector
      result = connector.make_request(:get, nil)

      expect(result).to eq(success: false, message: 'API endpoint not configured', data: nil)
      expect(connection).not_to have_received(:send)
    end

    it 'returns success response for 200 status' do
      response = instance_double(Faraday::Response, status: 200, body: { 'result' => 'ok' })
      allow(connection).to receive(:send).and_return(response)

      result = connector.make_request(:get, url)

      expect(result).to eq(success: true, data: { 'result' => 'ok' }, message: 'Operation successful')
    end

    it 'returns invalid credentials message for 401 status' do
      response = instance_double(Faraday::Response, status: 401, body: {})
      allow(connection).to receive(:send).and_return(response)

      result = connector.make_request(:get, url)

      expect(result).to eq(success: false, message: 'Invalid credentials', data: nil)
    end

    it 'returns custom error for 403 status' do
      response = instance_double(Faraday::Response, status: 403, body: { 'errors' => 'Forbidden' })
      allow(connection).to receive(:send).and_return(response)

      result = connector.make_request(:get, url)

      expect(result).to eq(success: false, message: 'Forbidden', data: nil)
    end

    it 'returns default message for 500 status without errors payload' do
      response = instance_double(Faraday::Response, status: 500, body: {})
      allow(connection).to receive(:send).and_return(response)

      result = connector.make_request(:get, url)

      expect(result).to eq(success: false, message: 'Service error', data: nil)
    end

    it 'handles Faraday timeout errors' do
      allow(connection).to receive(:send).and_raise(Faraday::TimeoutError.new('execution expired'))

      result = connector.make_request(:get, url)

      expect(result).to eq(success: false, message: 'Service timeout', data: nil)
    end

    it 'handles connection failures' do
      allow(connection).to receive(:send).and_raise(Faraday::ConnectionFailed.new('connection refused'))

      result = connector.make_request(:get, url)

      expect(result).to eq(success: false, message: 'Cannot connect to service', data: nil)
    end

    it 'handles Faraday errors' do
      allow(connection).to receive(:send).and_raise(Faraday::Error.new('faraday error'))

      result = connector.make_request(:get, url)

      expect(result).to eq(success: false, message: 'Network error', data: nil)
    end

    it 'handles generic errors' do
      allow(connection).to receive(:send).and_raise(StandardError.new('unexpected'))

      result = connector.make_request(:get, url)

      expect(result).to eq(success: false, message: 'Service temporarily unavailable', data: nil)
    end
  end
end
