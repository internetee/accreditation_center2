# app/validators/create_and_cancel_invoice_validator.rb
class CreateAndCancelInvoiceValidator < BaseTaskValidator
  # Config (optional):
  # {
  #   "window_minutes": 15
  # }
  #
  # Validates that the user created an invoice and then cancelled it recently.
  # Uses Accreditation API endpoint that lists cancelled invoices for the current registrar.
  def call
    api = []
    window_minutes, cutoff = compute_window_and_cutoff
    invoices = with_audit(api, 'cancelled_invoices') { @service.cancelled_invoices }
    recent_cancelled = recent_cancelled_invoices(invoices, cutoff)

    return pass(api, evidence_payload(recent_cancelled)) unless recent_cancelled.empty?

    failure(api, [I18n.t('validators.create_and_cancel_invoice.no_recently_cancelled_invoices', window: window_minutes)])
  end

  private

  def recent_cancelled_invoices(invoices, cutoff)
    return [] if invalid_invoice_payload?(invoices)

    invoices.select do |inv|
      cancelled_at = parse_time(inv[:cancelled_at])
      created_at   = parse_time(inv[:created_at]) || cancelled_at
      cancelled_at && cancelled_at >= cutoff && created_at && created_at <= cancelled_at
    end
  end

  def evidence_payload(recent_cancelled)
    {
      count: recent_cancelled.size,
      invoices: recent_cancelled.first(3)
    }
  end

  def api_service_adapter
    InvoiceService.new(token: @token)
  end

  def invalid_invoice_payload?(invoices)
    invoices.nil? || (invoices.is_a?(Hash) && invoices[:success] == false)
  end
end
