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
    api = []
    domain_name = rendered_domain_name
    info = fetch_domain_info(api, domain_name)
    return failure(api, [domain_not_found_message(domain_name)]) unless info && info[:success] != false

    statuses = info[:statuses] || {}
    return failure(api, [domain_not_pending_message(domain_name)]) unless statuses.key?(:pendingDelete)

    pass(api, { domain: { name: domain_name, statuses: statuses } })
  end

  private

  def rendered_domain_name
    template = @config['domain'] || '{{xfer_domain}}'
    Mustache.render(template.to_s, @attempt.vars)
  end

  def fetch_domain_info(api, domain_name)
    with_audit(api, 'domain_info') { @service.domain_info(name: domain_name) }
  end

  def domain_not_found_message(domain_name)
    I18n.t('validators.delete_domain_verified_validator.domain_not_found', domain: domain_name)
  end

  def domain_not_pending_message(domain_name)
    I18n.t('validators.delete_domain_verified_validator.domain_not_in_pending_delete_status', domain: domain_name)
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end
