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
    errs = []
    api  = []

    window = (@config['window_minutes'] || 15).to_i
    window = 15 if window <= 0
    cutoff = Time.current - window.minutes

    invoices = with_audit(api) { @service.cancelled_invoices }

    recent_cancelled = invoices.select do |inv|
      cancelled_at = parse_time(inv[:cancelled_at])
      created_at   = parse_time(inv[:created_at]) || cancelled_at
      cancelled_at && cancelled_at >= cutoff && created_at && created_at <= cancelled_at
    end

    if recent_cancelled.empty?
      errs << "No recently cancelled invoices found (last #{window} minutes)"
    end

    return pass(api, { count: recent_cancelled.size, invoices: recent_cancelled.first(3) }) if errs.empty?

    fail(api, errs)
  end

  private

  def with_audit(api)
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    res = yield
    api << { op: 'cancelled_invoices', ok: true, ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round }
    res
  rescue => e
    api << ({ op: 'cancelled_invoices', ok: false, error: e.message })
    []
  end

  def parse_time(val)
    return val if val.is_a?(Time) || val.is_a?(ActiveSupport::TimeWithZone)
    return nil if val.nil?

    Time.zone.parse(val.to_s) rescue nil
  end

  def pass(api, evidence = {})
    { passed: true, score: 1.0, evidence: evidence, error: nil, api_audit: api, export_vars: {} }
  end

  def fail(api, errs)
    { passed: false, score: 0.0, evidence: {}, error: errs.join('; '), api_audit: api, export_vars: {} }
  end

  def api_service_adapter
    InvoiceService.new(token: @token)
  end
end
