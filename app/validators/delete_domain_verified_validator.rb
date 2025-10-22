# app/validators/delete_domain_verified_validator.rb
class DeleteDomainVerifiedValidator < BaseTaskValidator
  # Config (optional; defaults shown):
  # {
  #   "domain": "{{xfer_domain}}"
  # }
  #
  # Validates that the domain has status pendingDelete immediately,
  # indicating a successful delete with verified=yes.
  #
  # Returns standard validator hash keys.
  def call
    errs = []
    api  = []

    template = @config['domain'] || '{{xfer_domain}}'
    name     = Mustache.render(template.to_s, @attempt.vars)

    info = info_with_audit(api, name)
    errs << "#{name} not found" and return fail(api, errs) if info.nil? || info[:success] == false

    # statuses is a hash, check if pendingDelete key exists
    statuses = info[:statuses] || {}
    has_pending_delete = statuses.key?(:pendingDelete)

    errs << "#{name} not in pendingDelete status" unless has_pending_delete

    return pass(api, domain: { name: name, statuses: statuses }) if errs.empty?

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
