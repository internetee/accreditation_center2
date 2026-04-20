# app/validators/transfer_domains_validator.rb
class TransferDomainsValidator < BaseTaskValidator
  # Validates that provided domains were transferred from bot registrar to user registrar.
  # Config:
  #   {
  #     "domains": ["{{xfer_domain}}"]
  #   }
  #
  # Validates that:
  # - The domains are transferred from bot registrar to user registrar
  #
  # Returns:
  #   passed(bool), score(0..1), evidence(Hash), error(String|nil), api_audit(Array), export_vars(Hash)
  def call
    api = []
    expected_domains = resolved_domains

    return failure(api, [domains_missing_message]) if expected_domains.empty?

    errors = expected_domains.flat_map { |fqdn| validate_transfer(api, fqdn) }
    return failure(api, errors) unless errors.empty?

    pass(api, expected_domains: expected_domains)
  end

  private

  def resolved_domains
    Array(@config['domains']).map { |d| Mustache.render(d.to_s, @attempt.vars) }.compact.uniq
  end

  def domains_missing_message
    I18n.t('validators.transfer_domains_validator.domains_array_missing')
  end

  def validate_transfer(api, domain_name)
    info = fetch_domain_info(api, domain_name)
    return [domain_not_found_message(domain_name)] if info.blank? || info[:success] == false

    errors = []
    registrar = info.dig(:registrar, :name)
    errors << registrar_missing_message(domain_name) if registrar.blank?
    errors << registrar_mismatch_message(domain_name) if registrar.present? && registrar != @attempt.user.registrar_name
    errors
  end

  def fetch_domain_info(api, name)
    with_audit(api, 'domain_info') { @service.domain_info(name: name) }
  end

  def domain_not_found_message(name)
    I18n.t('validators.transfer_domains_validator.domain_not_found', domain: name)
  end

  def registrar_missing_message(name)
    I18n.t('validators.transfer_domains_validator.domain_registrar_info_missing', domain: name)
  end

  def registrar_mismatch_message(name)
    I18n.t('validators.transfer_domains_validator.domain_registrar_mismatch', domain: name)
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end
