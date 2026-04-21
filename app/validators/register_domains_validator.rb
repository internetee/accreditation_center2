# app/validators/register_domains_validator.rb
class RegisterDomainsValidator < BaseTaskValidator
  # Config:
  # {
  #   "periods": {
  #     "{{domain1}}": "1y",
  #     "{{domain2}}": "2y"
  #   },
  #   "enforce_registrant_from_task1": true
  # }
  #
  # Validates that:
  # - The domains are registered with the correct period
  # - The registrant is the correct one
  #
  # Returns:
  #   passed(bool), score(0..1), evidence(Hash), error(String|nil), api_audit(Array), export_vars(Hash)
  def call
    api = []
    evidence = {}
    errors = []

    domain_configs.each do |domain|
      info = fetch_domain_info(api, domain[:name])
      if info.nil? || info[:success] == false
        errors << domain_not_found_message(domain[:name])
        next
      end

      domain_errors = validate_domain(info, domain)
      if domain_errors.empty?
        evidence[domain[:key]] = info
      else
        errors.concat(domain_errors)
      end
    end

    return failure(api, errors) unless errors.empty?

    pass(api, evidence)
  end

  private

  def domain_configs
    periods = @config['periods'] || {}
    keys = periods.keys
    [
      {
        key: :dom1,
        name: Mustache.render(keys[0].to_s, @attempt.vars),
        period: periods[keys[0]].to_s,
        registrant: v(:org_contact_id)
      },
      {
        key: :dom2,
        name: Mustache.render(keys[1].to_s, @attempt.vars),
        period: periods[keys[1]].to_s,
        registrant: v(:priv_contact_id)
      }
    ]
  end

  def fetch_domain_info(api, name)
    with_audit(api, 'domain_info') { @service.domain_info(name: name) }
  end

  def domain_not_found_message(name)
    I18n.t('validators.register_domains_validator.domain_not_found', domain: name)
  end

  def validate_domain(info, domain)
    errors = []
    errors.concat(period_errors(info, domain))
    errors.concat(registrant_presence_errors(info, domain))
    errors.concat(registrant_match_errors(info, domain))
    errors
  end

  def period_errors(info, domain)
    return [] if period_matches?(info, domain[:period])

    [
      I18n.t(
        'validators.register_domains_validator.domain_wrong_period',
        domain: domain[:name],
        period: domain[:period]
      )
    ]
  end

  def registrant_presence_errors(info, domain)
    return [] if info[:registrant].present?

    [
      I18n.t(
        'validators.register_domains_validator.domain_missing_registrant',
        domain: domain[:name]
      )
    ]
  end

  def registrant_match_errors(info, domain)
    return [] unless enforce_registrant?
    return [] if info.dig(:registrant, :code) == domain[:registrant]

    [
      I18n.t(
        'validators.register_domains_validator.domain_wrong_registrant',
        domain: domain[:name]
      )
    ]
  end

  def period_matches?(info, expected_period)
    expected_expiry = calculate_expiry(info[:created_at], expected_period)
    info[:expire_time].present? && expected_expiry.present? && info[:expire_time].to_date == expected_expiry.to_date
  end

  def enforce_registrant?
    @config['enforce_registrant_from_task1']
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end

  def calculate_expiry(created, period)
    return nil if created.blank? || period.blank?

    value, unit = parse_period(period)
    return nil unless value && unit

    apply_period(created.to_date, value, unit)
  end

  def parse_period(period)
    match = period.match(/\A(\d+)([ym])\z/i)
    return [nil, nil] unless match

    [match[1].to_i, match[2].downcase]
  end

  def apply_period(date, value, unit)
    case unit
    when 'y'
      (date.advance(years: value) + 1.day).beginning_of_day
    when 'm'
      (date.advance(months: value) + 1.day).beginning_of_day
    end
  end
end
