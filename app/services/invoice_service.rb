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
    return [] unless result[:success]

    data = result[:data]
    data = JSON.parse(data) if data.is_a?(String)

    invoices = if data.is_a?(Hash) && data.key?('invoices')
                 data['invoices']
               else
                 data
               end

    Array(invoices).map { |h| symbolize_keys_deep(h) }
  end
end
