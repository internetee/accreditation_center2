class RegistrantEmailMatchesUserValidator < BaseTaskValidator
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

    return failure(api, errors) unless errors.empty?

    email = contact[:email]
    expected = @attempt.user&.email.to_s

    if email.blank? || expected.blank? || email != expected
      errors << 'Registrant email does not match current user email'
      return failure(api, errors)
    end

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

  def api_service_adapter
    DomainService.new(token: @token)
  end
end

