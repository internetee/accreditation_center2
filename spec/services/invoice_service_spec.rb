require 'rails_helper'

RSpec.describe InvoiceService do
  let(:token) { 'token' }

  it 'returns success payload on valid credentials' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_INVOICES']}")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 200,
        body: {
          invoices: [
            { cancelled_at: '2021-09-03T13:53:15.393+03:00', total: '24.0' },
            { cancelled_at: '2021-09-04T13:53:15.393+03:00', total: '25.0' }
          ]
        }.to_json
      )
    result = service.cancelled_invoices

    expect(result).to be_an(Array)
    expect(result.size).to eq(2)
    expect(result.first).to include(cancelled_at: '2021-09-03T13:53:15.393+03:00', total: '24.0')
    expect(result.last).to include(cancelled_at: '2021-09-04T13:53:15.393+03:00', total: '25.0')
  end

  it 'returns failure payload on invalid credentials' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_INVOICES']}")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 401,
        body: { code: 2202, message: 'Invalid authorization information' }.to_json
      )

    expect(service.cancelled_invoices).to include(success: false, data: nil, message: I18n.t('errors.invalid_credentials'))
  end

  it 'returns invalid data format error on invalid data format' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_INVOICES']}")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 200,
        body: 'invalid data format'
      )

    expect(service.cancelled_invoices).to include(success: false, data: nil, message: I18n.t('errors.unexpected_response'))
  end

  it 'returns no cancelled invoices error on no cancelled invoices' do
    service = described_class.new(token: 'token')
    stub_request(:get, "#{ENV['BASE_URL']}#{ENV['GET_INVOICES']}")
      .with(headers: { 'Authorization' => "Basic #{token}" })
      .and_return(
        status: 404,
        body: { errors: 'No cancelled invoices' }.to_json
      )

    expect(service.cancelled_invoices).to include(success: false, data: nil, message: I18n.t('errors.object_not_found'))
  end
end
