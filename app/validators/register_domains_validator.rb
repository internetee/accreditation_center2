# app/validators/register_domains_validator.rb
class RegisterDomainsValidator < BaseTaskValidator
  def call
    # Expect Task 1 to have exported these:
    org_id  = v(:org_contact_id)
    priv_id = v(:priv_contact_id)

    errs = []
    api  = []

    # Resolve domains from config (already Mustache-rendered in controller)
    periods = @config['periods'] || {}
    k1, k2 = periods.keys[0].to_s, periods.keys[1].to_s
    d1 = Mustache.render(k1, @attempt.vars)
    d2 = Mustache.render(k2, @attempt.vars)
    y1 = periods[periods.keys[0]]
    y2 = periods[periods.keys[1]]

    # info for domain1 (ASCII)
    dom1 = info_with_audit(api, d1)

    errs << "#{d1} not found" and return fail(api, errs) if dom1[:success] == false

    errs << "#{d1} wrong period (want #{y1})" if dom1[:expire_time].to_date != calculate_expiry(dom1[:created_at], y1)
    errs << "#{d1} missing registrant" unless dom1[:registrant].present?
    errs << "#{d1} wrong registrant" if @config['enforce_registrant_from_task1'] && dom1.dig(:registrant, :code) != org_id

    # info for domain2 (ASCII punycode)
    dom2 = info_with_audit(api, d2)
    errs << "#{d2} not found" and return fail(api, errs) if dom2[:success] == false

    errs << "#{d2} wrong period (want #{y2})" if dom2[:expire_time].to_date != calculate_expiry(dom2[:created_at], y2)
    errs << "#{d2} missing registrant" unless dom2[:registrant].present?
    errs << "#{d2} wrong registrant" if @config['enforce_registrant_from_task1'] && dom2.dig(:registrant, :code) != priv_id

    return pass(api, dom1: dom1, dom2: dom2) if errs.empty?

    fail(api, errs)
  end

  private

  def info_with_audit(api, name)
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    res = @service.domain_info(name: name) # for IDN we passed punycode
    api << { op: 'domain_info', name: name, ok: !res.nil?, ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round }
    res
  rescue => e
    api << { op: 'domain_info', name: name, ok: false, error: e.message }
    nil
  end

  def pass(api, evidence = {})
    { passed: true, score: 1.0, evidence: evidence, error: nil, api_audit: api, export_vars: {} }
  end

  def fail(api, errs)
    { passed: false, score: 0.0, evidence: {}, error: errs.join('; '), api_audit: api, export_vars: {} }
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end

  def calculate_expiry(created, period)
    return nil if created.nil? || period.nil?

    # Parse period string
    match = period.match(/\A(\d+)([ym])\z/i)
    return nil unless match

    value = match[1].to_i
    unit = match[2].downcase

    expiry =
      case unit
      when 'y'
        (created.to_date.advance(years: value) + 1.day).beginning_of_day
      when 'm'
        (created.to_date.advance(months: value) + 1.day).beginning_of_day
      else
        return nil
      end

    expiry
  end
end
