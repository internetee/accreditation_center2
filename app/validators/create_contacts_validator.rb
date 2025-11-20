# app/validators/create_contacts_validator.rb
class CreateContactsValidator < BaseTaskValidator
  # Config (optional):
  # {
  #   "window_minutes": 15
  # }
  #
  # Validates that the user created two contacts recently.
  # Uses Accreditation API endpoint that lists contacts for the current registrar.
  def call
    org_id, priv_id = contact_ids
    _window_minutes, cutoff_time = compute_window_and_cutoff
    api = []

    org_contact = fetch_contact_with_audit(api, org_id)
    priv_contact = fetch_contact_with_audit(api, priv_id)

    errors = validate_contacts(org_contact, priv_contact, cutoff_time)
    return failure(api, errors) unless errors.empty?

    pass(
      api,
      { org: org_contact, per: priv_contact },
      { 'org_contact_id' => org_id, 'priv_contact_id' => priv_id }
    )
  end

  def contact_ids
    [@inputs['org_contact_id'], @inputs['priv_contact_id']]
  end

  def fetch_contact_with_audit(api, contact_id)
    with_audit(api, 'contact_info') { @service.contact_info(id: contact_id) }
  end

  def validate_contacts(org, priv, cutoff_time)
    errors = []
    errors.concat(presence_errors(org, priv))
    errors.concat(type_errors(org, priv))
    errors.concat(field_errors(org, priv))
    errors.concat(recency_errors(org, priv, cutoff_time))
    errors.compact
  end

  def presence_errors(org, priv)
    [].tap do |errors|
      if org.nil? || org[:success] == false
        errors << I18n.t('validators.create_contacts_validator.organization_contact_not_found')
      end
      if priv.nil? || priv[:success] == false
        errors << I18n.t('validators.create_contacts_validator.private_contact_not_found')
      end
    end
  end

  def type_errors(org, priv)
    [].tap do |errors|
      errors << I18n.t('validators.create_contacts_validator.org_type_mismatch') unless valid_type?(org, 'org')
      errors << I18n.t('validators.create_contacts_validator.priv_type_mismatch') unless valid_type?(priv, 'priv')
    end
  end

  def field_errors(org, priv)
    [].tap do |errors|
      unless org && required_fields_present?(org)
        errors << I18n.t('validators.create_contacts_validator.org_required_fields_missing')
      end
      unless priv && required_fields_present?(priv)
        errors << I18n.t('validators.create_contacts_validator.priv_required_fields_missing')
      end
    end
  end

  def recency_errors(org, priv, cutoff_time)
    [].tap do |errors|
      unless recent_enough?(org, cutoff_time)
        errors << I18n.t('validators.create_contacts_validator.org_contact_not_recent')
      end
      unless recent_enough?(priv, cutoff_time)
        errors << I18n.t('validators.create_contacts_validator.priv_contact_not_recent')
      end
    end
  end

  def valid_type?(contact, expected_type)
    contact && contact.dig(:ident, :type) == expected_type
  end

  def required_fields_present?(contact)
    %i[code name ident phone email].all? { |k| contact && contact[k].present? }
  end

  def recent_enough?(contact, cutoff_time)
    created_at = parse_time(contact&.fetch(:created_at, nil))
    created_at.present? && created_at >= cutoff_time
  end

  def api_service_adapter
    ContactService.new(token: @token)
  end
end
