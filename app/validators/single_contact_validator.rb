class SingleContactValidator < BaseTaskValidator
  def call
    id = @inputs[contact_input_key]
    api = []
    errors = []

    contact = with_audit(api, 'contact_info') do
      id.present? ? contact_service.contact_info(id: id) : nil
    end

    if contact.nil? || contact[:success] == false
      errors << 'Contact not found'
    else
      errors.concat(type_errors(contact))
      errors.concat(field_errors(contact))
      errors.concat(recency_errors(contact))
    end

    return failure(api, errors) unless errors.empty?

    pass(api, { contact: contact }, { contact_input_key => id })
  end

  private

  def contact_input_key
    (@config['input_key'] || 'contact_id').to_s
  end

  def expected_type
    (@config['expected_type'] || '').to_s
  end

  def contact_service
    @contact_service ||= ContactService.new(token: @token)
  end

  def type_errors(contact)
    return [] if expected_type.blank?

    contact_type = contact.dig(:ident, :type)
    return [] if contact_type == expected_type

    ["Contact type mismatch (expected #{expected_type})"]
  end

  def field_errors(contact)
    required_keys = %i[code name ident phone email]
    return [] if required_keys.all? { |k| contact[k].present? }

    ['Required contact fields are missing']
  end

  def recency_errors(contact)
    _window, cutoff = compute_window_and_cutoff
    created_at = parse_time(contact[:created_at])
    return [] if created_at && created_at >= cutoff

    ['Contact is not recent enough']
  end

  def api_service_adapter
    domain_service_placeholder
  end

  def domain_service_placeholder
    DomainService.new(token: @token)
  end
end

