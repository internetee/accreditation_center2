require 'rails_helper'

RSpec.describe AuthenticationService do
  let(:token) { 'dXA6cDI=' }

  before do
    expect(ApiTokenService).to receive(:new).with(username: 'u', password: 'p').and_return(double(generate: token))
  end

  it 'returns success payload on valid credentials' do
    service = described_class.new(username: 'u', password: 'p')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['AUTH_API_URL']}")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 200,
        body: {
          code: 1000,
          message: 'Command completed successfully',
          data: {
            id: 1,
            username: 'u',
            registrar_email: 'e',
            registrar_name: 'n',
            accreditation_date: Date.current,
            accreditation_expire_date: 1.year.from_now.to_date
          }
        }.to_json
      )

    expect(service.authenticate_user[:success]).to be(true)
  end

  it 'returns failure payload on invalid credentials' do
    service = described_class.new(username: 'u', password: 'p')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['AUTH_API_URL']}").to_return(
      status: 401,
      body: {
        code: 2202,
        message: 'Invalid authorization information'
      }.to_json
    )

    expect(service.authenticate_user).to include(success: false, data: nil, message: I18n.t('errors.invalid_credentials'))
  end

  it 'returns invalid data format error on invalid data format' do
    service = described_class.new(username: 'u', password: 'p')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['AUTH_API_URL']}").to_return(
      status: 200,
      body: 'invalid data format'
    )

    expect(service.authenticate_user).to include(success: false, data: nil, message: I18n.t('errors.unexpected_response'))
  end
end
