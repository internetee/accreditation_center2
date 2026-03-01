class RegisterSingleDomainValidator < BaseTaskValidator
  def call
    api = []
    errors = []

    domain_name = Mustache.render(@config['domain_template'].to_s, @attempt.vars)
    if domain_name.blank?
      errors << 'Domain name is missing'
      return failure(api, errors)
    end

    info = with_audit(api, 'domain_info') { @service.domain_info(name: domain_name) }
    if info.nil? || info[:success] == false
      errors << "Domain #{domain_name} not found"
      Rails.logger.info "[RegisterSingleDomainValidator] domain=#{domain_name} domain_info failed: info=#{info.inspect}"
      return failure(api, errors)
    end

    errors.concat(period_errors(info))
    errors.concat(registrant_errors(info))

    unless errors.empty?
      Rails.logger.info "[RegisterSingleDomainValidator] domain=#{domain_name} errors=#{errors.inspect} info=#{info&.slice(:name, :expire_time, :created_at, :registrant)}"
      return failure(api, errors)
    end

    pass(api, { domain: info })
  end

  private

  def expected_period
    @config['period'].to_s
  end

  def registrant_var
    (@config['registrant_var'] || '').to_s
  end

  def period_errors(info)
    return [] if expected_period.blank?

    created = info[:created_at]
    expected_expiry = calculate_expiry(created, expected_period)
    return [] if info[:expire_time].present? && expected_expiry.present? &&
                info[:expire_time].to_date == expected_expiry.to_date

    ["Domain #{info[:name]} does not have expected period #{expected_period}"]
  end

  def registrant_errors(info)
    return [] if registrant_var.blank?

    expected_code = v(registrant_var)
    actual_code = info.dig(:registrant, :code)
    errors = []

    errors << 'Domain registrant missing' if actual_code.blank?
    if expected_code.present? && actual_code.present? && actual_code != expected_code
      errors << 'Domain registrant does not match expected contact'
    end

    errors
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

  def api_service_adapter
    DomainService.new(token: @token)
  end
end

