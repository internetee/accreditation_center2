class ClientHoldStatusValidator < BaseTaskValidator
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
      errors << 'Domain not found'
      return failure(api, errors)
    end

    statuses = (info[:statuses] || {}).keys.map(&:to_s)
    expect_absent = @config['expect_absent']
    if expect_absent
      if statuses.include?('clientHold')
        errors << 'Domain still has clientHold status; remove it via the registrar portal'
        return failure(api, errors)
      end
    else
      unless statuses.include?('clientHold')
        errors << 'Domain is not in clientHold status'
        return failure(api, errors)
      end
    end

    pass(api, { domain: info })
  end

  private

  def api_service_adapter
    DomainService.new(token: @token)
  end
end

