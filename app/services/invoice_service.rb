# frozen_string_literal: true

# Service for retrieving invoices from the registry API for accreditation tasks.
# Exposes `cancelled_invoices` returning an array of symbolized hashes.
class InvoiceService < ApiConnector
  def initialize(token:)
    @api_url = ENV['BASE_URL'] + ENV['GET_INVOICES']
    super(token: token)
  end

  def cancelled_invoices
    result = make_request(:get, @api_url, { headers: @headers })
    return result unless result[:success]

    data = result[:data]
    data = parse_json(data)

    if data.is_a?(Hash) && data.key?('invoices')
      Array(data['invoices']).map { |h| symbolize_keys_deep(h) }
    else
      error_response(nil, I18n.t('errors.unexpected_response'))
    end
  end
end
