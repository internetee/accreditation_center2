# app/validators/transfer_domains_validator.rb
class TransferDomainsValidator < BaseTaskValidator
  # Validates that provided domains were transferred from bot registrar to user registrar.
  # Config:
  #   {
  #     "domains": ["{{xfer_domain}}"]
  #   }
  def call
    errs = []
    api  = []

    expected_domains = Array(@config['domains']).map { |d| Mustache.render(d.to_s, @attempt.vars) }.compact.uniq

    if expected_domains.empty?
      return fail(api, ["validator config must include 'domains' array"])
    end

    # For each domain, check it exists and is now sponsored by current registrar
    expected_domains.each do |fqdn|
      info = info_with_audit(api, fqdn)
      if info[:success] == false
        errs << "#{fqdn} not found"
        next
      end

      registrar = info.dig(:registrar, :name)
      if registrar.blank?
        errs << "#{fqdn} registrar info missing"
      end

      if registrar != @attempt.user.registrar_name
        errs << "#{fqdn} registrar mismatch"
      end
    end

    return pass(api, { expected_domains: expected_domains }) if errs.empty?

    fail(api, errs)
  end

  private

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
