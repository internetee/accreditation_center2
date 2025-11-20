require 'rails_helper'

RSpec.describe ContactService do
  let(:token) { 'token' }

  it 'returns success payload on valid credentials' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_CONTACT']}?id=1")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 200,
        body: {
          contact: {
            id: 1,
            name: 'John Doe',
            email: 'john.doe@example.com'
          }
        }.to_json
      )

    expect(service.contact_info(id: 1)).to include({ id: 1, name: 'John Doe', email: 'john.doe@example.com' })
  end

  it 'returns failure payload on invalid credentials' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_CONTACT']}?id=1")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 401,
        body: { code: 2202, message: 'Invalid authorization information' }.to_json
      )

    expect(service.contact_info(id: 1)).to include(success: false, data: nil, message: I18n.t('errors.invalid_credentials'))
  end

  it 'returns contact not found error on contact not found' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_CONTACT']}?id=1")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 404,
        body: { errors: 'Contact not found' }.to_json
      )

    expect(service.contact_info(id: 1)).to include(success: false, data: nil, message: I18n.t('errors.object_not_found'))
  end

  it 'returns invalid data format error on invalid data format' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_CONTACT']}?id=1")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 200,
        body: 'invalid data format'
      )

    expect(service.contact_info(id: 1)).to include(success: false, data: nil, message: I18n.t('errors.unexpected_response'))
  end
end
