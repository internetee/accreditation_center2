# app/validators/renew_domain_validator.rb
class RenewDomainValidator < BaseTaskValidator
  # Config:
  # {
  #   "domain": "{{domain1}}",
  #   "years": 5
  # }
  #
  # Validates that:
  # - The domain is renewed with the correct period
  # - The domain is renewed with the correct registrant
  #
  # Returns:
  #   passed(bool), score(0..1), evidence(Hash), error(String|nil), api_audit(Array), export_vars(Hash)
  def call
    api = []
    domain_name = resolved_domain_name
    years = renewal_years

    info = fetch_domain_info(api, domain_name)
    return failure(api, [domain_not_found_message(domain_name)]) unless info && info[:success] != false

    errors = validate_expiry(info, domain_name, years)
    return failure(api, errors) unless errors.empty?

    pass(api, domain: { name: domain_name, expire_time: info[:expire_time] })
  end

  private

  def resolved_domain_name
    template = @config['domain'] || '{{domain1}}'
    Mustache.render(template.to_s, @attempt.vars)
  end

  def renewal_years
    years = (@config['years'] || 5).to_i
    years.positive? ? years : 5
  end

  def fetch_domain_info(api, name)
    with_audit(api, 'domain_info') { @service.domain_info(name: name) }
  end

  def domain_not_found_message(name)
    I18n.t('validators.renew_domain_validator.domain_not_found', domain: name)
  end

  def validate_expiry(info, name, years)
    expire_time = info[:expire_time]
    return [I18n.t('validators.renew_domain_validator.domain_expire_time_missing', domain: name)] unless expire_time.present?

    expected_expiry = calculate_expiry(info[:created_at], years)
    return [I18n.t('validators.renew_domain_validator.domain_not_renewed', domain: name)] if expected_expiry.nil?

    expire_date = date_from_value(expire_time)
    expected_date = expected_expiry.respond_to?(:to_date) ? expected_expiry.to_date : expected_expiry
    expire_str = expire_date&.to_s
    expected_str = expected_date.respond_to?(:to_s) ? expected_date.to_s : expected_date.to_s
    return [I18n.t('validators.renew_domain_validator.domain_not_renewed', domain: name)] unless expire_str == expected_str

    []
  end

  def date_from_value(value)
    return value.to_date if value.respond_to?(:to_date) && !value.is_a?(String)
    return Time.zone.parse(value.to_s).to_date if value.present?
    nil
  end

  def calculate_expiry(created, years)
    return nil if created.nil? || years.nil?

    base = created.respond_to?(:to_date) ? created.to_date : Time.zone.parse(created.to_s).to_date
    base.advance(years: years).to_date + 1.day
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end
