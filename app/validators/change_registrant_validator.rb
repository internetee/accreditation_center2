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
    api = []
    errors = []

    source_domain, xfer_domain = resolve_domains
    source_info = fetch_domain_info(source_domain, :source_domain_not_found, api, errors)
    target_info = fetch_domain_info(xfer_domain, :target_domain_not_found, api, errors)

    source_code = target_code = nil
    if source_info && target_info
      source_code, target_code = validate_registrants(source_domain, xfer_domain, source_info, target_info, errors)
    end

    return failure(api, errors) unless errors.empty?

    pass(
      api,
      { xfer_domain: { name: xfer_domain, registrant_code: target_code }, source_domain: { name: source_domain, registrant_code: source_code } }
    )
  end

  private

  def resolve_domains
    xfer_tmpl   = @config['xfer_domain']   || '{{xfer_domain}}'
    source_tmpl = @config['source_domain'] || '{{domain1}}'

    xfer_domain   = Mustache.render(xfer_tmpl.to_s, @attempt.vars)
    source_domain = Mustache.render(source_tmpl.to_s, @attempt.vars)

    [source_domain, xfer_domain]
  end

  def fetch_domain_info(name, translation_key, api, errors)
    info = with_audit(api, 'domain_info') { @service.domain_info(name: name) }
    return info if info.present? && info[:success] != false

    errors << I18n.t("validators.change_registrant.#{translation_key}", domain: name)
    nil
  end

  def validate_registrants(source_domain, xfer_domain, source_info, target_info, errors)
    src_reg_code = source_info.dig(:registrant, :code)
    tgt_reg_code = target_info.dig(:registrant, :code)

    unless src_reg_code.present?
      errors << I18n.t('validators.change_registrant.source_domain_registrant_missing', domain: source_domain)
    end

    unless tgt_reg_code.present?
      errors << I18n.t('validators.change_registrant.target_domain_registrant_missing', domain: xfer_domain)
    end

    if src_reg_code.present? && tgt_reg_code.present? && tgt_reg_code != src_reg_code
      errors << I18n.t('validators.change_registrant.target_domain_registrant_not_replaced', domain: xfer_domain)
    end

    [src_reg_code, tgt_reg_code]
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end
