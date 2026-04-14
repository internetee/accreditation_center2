# app/validators/verify_contact_validator.rb
class VerifyContactValidator < BaseTaskValidator
  # Config (optional):
  # {
  #   "window_minutes": 15
  # }
  #
  # Validates that the user verified a contact recently.
  # Uses Accreditation API endpoint that lists contacts for the current registrar.
  def call
    contact_id = v(:priv_contact_id)
    _window_minutes, cutoff_time = compute_window_and_cutoff
    api = []

    contact = fetch_contact_with_audit(api, contact_id)

    errors = validate_contact(contact, cutoff_time)
    return failure(api, errors) unless errors.empty?

    pass(api, { contact: contact })
  end

  def fetch_contact_with_audit(api, contact_id)
    with_audit(api, 'contact_info') { @service.contact_info(id: contact_id) }
  end

  def validate_contact(contact, cutoff_time)
    errors = []
    errors.concat(presence_errors(contact))
    errors.concat(field_errors(contact))
    errors.concat(recency_errors(contact, cutoff_time))
    errors.compact
  end

  def presence_errors(contact)
    [].tap do |errors|
      if contact.nil? || contact[:success] == false
        errors << I18n.t('validators.verify_contact_validator.contact_not_found')
      end
    end
  end

  def field_errors(contact)
    [].tap do |errors|
      unless contact && required_fields_present?(contact)
        errors << I18n.t('validators.verify_contact_validator.contact_not_verified')
      end
    end
  end

  def required_fields_present?(contact)
    %i[code name ident phone email verification_id verified_at ident_request_sent_at].all? { |k| contact && contact[k].present? }
  end

  def recency_errors(contact, cutoff_time)
    [].tap do |errors|
      unless recent_enough?(contact, cutoff_time)
        errors << I18n.t('validators.verify_contact_validator.contact_not_recent')
      end
    end
  end

  def recent_enough?(contact, cutoff_time)
    verified_at = parse_time(contact&.fetch(:verified_at, nil))
    ident_request_sent_at = parse_time(contact&.fetch(:ident_request_sent_at, nil))
    verified_at.present? && verified_at >= cutoff_time && ident_request_sent_at.present? && ident_request_sent_at >= cutoff_time
  end

  def api_service_adapter
    ContactService.new(token: @token)
  end
end
