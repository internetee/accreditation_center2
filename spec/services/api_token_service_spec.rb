require 'rails_helper'

RSpec.describe ApiTokenService do
  let(:username) { 'api_user' }
  let(:password) { 'api_pass' }
  let(:service) { described_class.new(username: username, password: password) }

  describe '#generate' do
    context 'when method is base64 (default)' do
      before { ENV['API_TOKEN_METHOD'] = nil }

      it 'returns a base64 encoded token' do
        expected = Base64.strict_encode64("#{username}:#{password}")
        expect(service.generate).to eq(expected)
      end
    end

    context 'when method is explicitly base64' do
      before { ENV['API_TOKEN_METHOD'] = 'base64' }

      it 'returns a base64 encoded token' do
        expected = Base64.strict_encode64("#{username}:#{password}")
        expect(service.generate).to eq(expected)
      end
    end

    context 'when method is hmac' do
      let(:timestamp) { 1_700_000_000 }

      before do
        ENV['API_TOKEN_METHOD'] = 'hmac'
        ENV['API_SECRET_KEY'] = 'secret'
        allow(Time).to receive(:current).and_return(Time.at(timestamp))
      end

      it 'returns an HMAC hexdigest using the secret key' do
        token_data = "#{username}:#{password}:#{timestamp}"
        expected = OpenSSL::HMAC.hexdigest('SHA256', 'secret', token_data)

        expect(service.generate).to eq(expected)
      end

      it 'uses default secret key when API_SECRET_KEY is missing' do
        ENV['API_SECRET_KEY'] = nil
        token_data = "#{username}:#{password}:#{timestamp}"
        expected = OpenSSL::HMAC.hexdigest('SHA256', 'default_secret_key', token_data)

        expect(service.generate).to eq(expected)
      end
    end

    context 'when method is simple' do
      let(:timestamp) { 1_700_000_001 }

      before do
        ENV['API_TOKEN_METHOD'] = 'simple'
        allow(Time).to receive(:current).and_return(Time.at(timestamp))
      end

      it 'returns a simple token with timestamp' do
        expected = "#{username}:#{password}:#{timestamp}"
        expect(service.generate).to eq(expected)
      end
    end

    context 'when method is unknown' do
      before { ENV['API_TOKEN_METHOD'] = 'unknown' }

      it 'falls back to base64 token' do
        expected = Base64.strict_encode64("#{username}:#{password}")
        expect(service.generate).to eq(expected)
      end
    end
  end
end
