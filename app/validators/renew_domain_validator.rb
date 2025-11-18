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
    return [I18n.t('validators.renew_domain_validator.domain_not_renewed', domain: name)] unless expire_time.to_date == expected_expiry.to_date

    []
  end

  def calculate_expiry(created, years)
    return nil if created.nil? || years.nil?

    (created.to_date.advance(years: years) + 1.day).beginning_of_day
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end
