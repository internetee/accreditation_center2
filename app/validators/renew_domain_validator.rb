# app/validators/renew_domain_validator.rb
class RenewDomainValidator < BaseTaskValidator
  def call
    errs = []
    api  = []

    # Resolve domain from config (Mustache-rendered)
    template = @config['domain'] || '{{domain1}}'
    years    = (@config['years'] || 5).to_i
    years = 5 if years <= 0

    name = Mustache.render(template.to_s, @attempt.vars)

    info = info_with_audit(api, name)
    errs << "#{name} not found" and return fail(api, errs) if info[:success] == false

    exp = info[:expire_time]
    if exp.nil?
      errs << "#{name} expire_time missing"
    else
      errs << "#{name} not renewed" if exp.to_date != calculate_expiry(info[:created_at], years)
    end

    return pass(api, domain: { name: name, expire_time: exp }) if errs.empty?

    fail(api, errs)
  end

  private

  def calculate_expiry(created, years)
    return nil if created.nil? || years.nil?

    (created.to_date.advance(years: years) + 1.day).beginning_of_day
  end

  def info_with_audit(api, name)
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    res = @service.domain_info(name: name)
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
end
