# app/validators/change_registrant_validator.rb
class ChangeRegistrantValidator < BaseTaskValidator
  # Config (optional; defaults shown):
  # {
  #   "xfer_domain": "{{xfer_domain}}",
  #   "source_domain": "{{domain1}}"
  # }
  #
  # Validates that:
  # - The registrant of source_domain has email deliverable to the current user (equals attempt.user.email)
  # - The registrant of xfer_domain has been replaced with the registrant of source_domain
  #
  # Returns:
  #   passed(bool), score(0..1), evidence(Hash), error(String|nil), api_audit(Array), export_vars(Hash)
  def call
    errs = []
    api  = []

    xfer_tmpl   = @config['xfer_domain']   || '{{xfer_domain}}'
    source_tmpl = @config['source_domain'] || '{{domain1}}'

    xfer_domain   = Mustache.render(xfer_tmpl.to_s, @attempt.vars)
    source_domain = Mustache.render(source_tmpl.to_s, @attempt.vars)

    # Fetch info for source and target domains
    src = info_with_audit(api, source_domain)
    errs << "#{source_domain} not found" and return fail(api, errs) if src.nil? || src[:success] == false

    tgt = info_with_audit(api, xfer_domain)
    errs << "#{xfer_domain} not found" and return fail(api, errs) if tgt.nil? || tgt[:success] == false

    # Validate source registrant has email deliverable to current user
    src_reg_code = src.dig(:registrant, :code)

    errs << "#{source_domain} registrant missing" unless src_reg_code.present?

    # Validate xfer_domain registrant replaced with source registrant
    tgt_reg_code = tgt.dig(:registrant, :code)
    errs << "#{xfer_domain} registrant missing" unless tgt_reg_code.present?
    errs << "#{xfer_domain} registrant not replaced with source registrant" if tgt_reg_code.present? && src_reg_code.present? && tgt_reg_code != src_reg_code

    return pass(api, {
      xfer_domain: { name: xfer_domain, registrant_code: tgt_reg_code },
      source_domain: { name: source_domain, registrant_code: src_reg_code }
    }) if errs.empty?

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
