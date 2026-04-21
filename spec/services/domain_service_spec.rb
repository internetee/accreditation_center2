require 'rails_helper'

RSpec.describe DomainService do
  let(:token) { 'token' }

  it 'returns success payload on valid credentials' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_DOMAIN_INFO']}?name=example.ee")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 200,
        body: { domain: { name: 'example.ee', status: 'ok' } }.to_json
      )

    expect(service.domain_info(name: 'example.ee')).to include({ name: 'example.ee', status: 'ok' })
  end

  it 'returns failure payload on invalid credentials' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_DOMAIN_INFO']}?name=example.ee")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 401,
        body: { code: 2202, message: 'Invalid authorization information' }.to_json
      )

    expect(service.domain_info(name: 'example.ee')).to include(success: false, data: nil, message: I18n.t('errors.invalid_credentials'))
  end

  it 'returns domain not found error on domain not found' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_DOMAIN_INFO']}?name=example.ee")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 404,
        body: { errors: 'Domain not found' }.to_json
      )

    expect(service.domain_info(name: 'example.ee')).to include(success: false, data: nil, message: I18n.t('errors.object_not_found'))
  end

  it 'returns invalid data format error on invalid data format' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_DOMAIN_INFO']}?name=example.ee")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 200,
        body: 'invalid data format'
      )

    expect(service.domain_info(name: 'example.ee')).to include(success: false, data: nil, message: I18n.t('errors.unexpected_response'))
  end
end
