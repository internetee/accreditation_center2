# app/validators/update_nameservers_validator.rb
class UpdateNameserversValidator < BaseTaskValidator
  def call
    errs = []
    api  = []

    # Resolve domains from config (already Mustache-rendered in controller)
    ns_cfg = @config['nameservers'] || {}
    return fail(api, ['nameservers config missing or empty']) if ns_cfg.blank? || ns_cfg.keys.size < 2

    k1, k2 = ns_cfg.keys[0].to_s, ns_cfg.keys[1].to_s
    d1 = Mustache.render(k1, @attempt.vars)
    d2 = Mustache.render(k2, @attempt.vars)

    expected_ns1 = Array(ns_cfg[ns_cfg.keys[0]]).map { |ns| normalize_ns(Mustache.render(ns.to_s, @attempt.vars)) }.compact.uniq.sort
    expected_ns2 = Array(ns_cfg[ns_cfg.keys[1]]).map { |ns| normalize_ns(Mustache.render(ns.to_s, @attempt.vars)) }.compact.uniq.sort

    # info for domain1
    dom1 = info_with_audit(api, d1)
    errs << "#{d1} not found" and return fail(api, errs) if dom1[:success] == false

    actual_ns1 = extract_nameservers(dom1)
    errs << "#{d1} nameservers mismatch" unless set_matches?(actual_ns1, expected_ns1)

    # info for domain2
    dom2 = info_with_audit(api, d2)
    errs << "#{d2} not found" and return fail(api, errs) if dom2[:success] == false

    actual_ns2 = extract_nameservers(dom2)
    errs << "#{d2} nameservers mismatch" unless set_matches?(actual_ns2, expected_ns2)

    return pass(api, dom1: { name: d1, actual: actual_ns1, expected: expected_ns1 },
                     dom2: { name: d2, actual: actual_ns2, expected: expected_ns2 }) if errs.empty?

    fail(api, errs)
  end

  private

  def extract_nameservers(info_hash)
    Array(info_hash[:nameservers]).map do |ns|
      if ns.is_a?(Hash)
        normalize_ns(ns[:hostname] || ns[:name])
      else
        normalize_ns(ns)
      end
    end.compact.uniq.sort
  end

  def normalize_ns(value)
    return nil if value.nil?

    value.to_s.strip.downcase.chomp('.')
  end

  def set_matches?(actual, expected)
    actual.sort == expected.sort
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
