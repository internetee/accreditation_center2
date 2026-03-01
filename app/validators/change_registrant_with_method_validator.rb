class ChangeRegistrantWithMethodValidator < BaseTaskValidator
  def call
    api = []
    errors = []

    source_name, target_name = resolve_domains
    if source_name.blank? || target_name.blank?
      errors << 'Source or target domain is missing'
      return failure(api, errors)
    end

    source = with_audit(api, 'domain_info') { @service.domain_info(name: source_name) }
    target = with_audit(api, 'domain_info') { @service.domain_info(name: target_name) }

    if source.nil? || source[:success] == false
      errors << "Source domain #{source_name} not found"
    end
    if target.nil? || target[:success] == false
      errors << "Target domain #{target_name} not found"
    end
    return failure(api, errors) unless errors.empty?

    errors.concat(registrant_errors(source, target))
    errors.concat(method_errors(target))

    return failure(api, errors) unless errors.empty?

    pass(api, { source_domain: source, target_domain: target })
  end

  private

  def resolve_domains
    source_tmpl = @config['source_domain'] || ''
    target_tmpl = @config['target_domain'] || ''

    source_name = Mustache.render(source_tmpl.to_s, @attempt.vars)
    target_name = Mustache.render(target_tmpl.to_s, @attempt.vars)

    [source_name, target_name]
  end

  def expected_method
    (@config['expected_method'] || '').to_s
  end

  def registrant_errors(source, target)
    src = source.dig(:registrant, :code)
    tgt = target.dig(:registrant, :code)
    errors = []

    errors << 'Source domain registrant missing' if src.blank?
    errors << 'Target domain registrant missing' if tgt.blank?
    errors << 'Target registrant does not match source registrant' if src.present? && tgt.present? && src != tgt

    errors
  end

  def method_errors(target)
    method = target[:last_registrant_change_method].to_s
    return [] if expected_method.blank? || method == expected_method

    ["Last registrant change method #{method} does not match expected #{expected_method}"]
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end

