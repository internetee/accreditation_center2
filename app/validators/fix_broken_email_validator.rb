class FixBrokenEmailValidator < BaseTaskValidator
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

    contact, contact_errors = load_registrant_contact(info, api)
    errors.concat(contact_errors)

    errors.concat(email_errors(contact))
    errors.concat(status_errors(info))

    return failure(api, errors) unless errors.empty?

    pass(api, { domain: info, contact: contact })
  end

  private

  def load_registrant_contact(domain_info, api)
    code = domain_info.dig(:registrant, :code)
    return [nil, ['Registrant code missing on domain']] if code.blank?

    contact = with_audit(api, 'contact_info') do
      ContactService.new(token: @token).contact_info(id: code)
    end

    return [contact, []] if contact && contact[:success] != false

    [contact, ['Registrant contact not found']]
  end

  def email_errors(contact)
    email = contact && contact[:email]
    return ['Contact email missing'] if email.blank?

    expected = @attempt.user&.email.to_s
    return ['Current user email missing'] if expected.blank?

    return [] if email.count('@') == 1 && !email.include?(' ') && email == expected

    ['Broken domain is not fixed: registrant email must be updated to match your login email']
  end

  def status_errors(domain_info)
    statuses = (domain_info[:statuses] || {}).keys.map(&:to_s)
    prohibited = %w[forceDelete serverRenewProhibited serverTransferProhibited clientRenewProhibited clientTransferProhibited]

    return [] if (statuses & prohibited).empty?

    ['Broken domain is not fixed: force delete / renew / transfer restrictions are still present']
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end

