# app/validators/create_contacts_validator.rb
class CreateContactsValidator < BaseTaskValidator
  def call
    org_id  = @inputs['org_contact_id']
    priv_id = @inputs['priv_contact_id']

    # Configurable time window for recent creation (default 15 minutes)
    window_minutes = (@config['window_minutes'] || 1440000).to_i
    window_minutes = 15 if window_minutes <= 0
    cutoff_time = Time.current - window_minutes.minutes

    api = []
    org = begin
      with_audit(api) { @service.contact_info(id: org_id) }
    rescue
      nil
    end
    per = begin
      with_audit(api) { @service.contact_info(id: priv_id) }
    rescue
      nil
    end

    errors = []
    errors << I18n.t('validators.create_contacts_validator.organization_contact_not_found') unless org
    errors << I18n.t('validators.create_contacts_validator.private_contact_not_found') unless per
    errors << I18n.t('validators.create_contacts_validator.org_type_mismatch')  unless org && org.dig(:ident, :type)  == 'org'
    errors << I18n.t('validators.create_contacts_validator.priv_type_mismatch') unless per && per.dig(:ident, :type)  == 'priv'
    errors << I18n.t('validators.create_contacts_validator.org_required_fields_missing')  unless org && required_fields_present?(org)
    errors << I18n.t('validators.create_contacts_validator.priv_required_fields_missing') unless per && required_fields_present?(per)

    # Check if contacts were created recently
    errors << I18n.t('validators.create_contacts_validator.org_contact_not_recent') if org && !recently_created?(org, cutoff_time)
    errors << I18n.t('validators.create_contacts_validator.priv_contact_not_recent') if per && !recently_created?(per, cutoff_time)

    passed = errors.empty?
    export = passed ? { 'org_contact_id' => org_id, 'priv_contact_id' => priv_id } : {}

    {
      passed: passed,
      score: passed ? 1.0 : 0.0,
      evidence: { org: org, per: per },
      error: passed ? nil : errors.join('; '),
      api_audit: api,
      export_vars: export
    }
  end

  def required_fields_present?(contact)
    %i[code name ident phone email].all? { |k| contact[k].present? }
  end

  def recently_created?(contact, cutoff_time)
    created_at = parse_time(contact[:created_at])
    return false if created_at.nil?

    created_at >= cutoff_time
  end

  def parse_time(val)
    return val if val.is_a?(Time) || val.is_a?(ActiveSupport::TimeWithZone)
    return nil if val.nil?

    Time.zone.parse(val.to_s) rescue nil
  end

  def with_audit(api)
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    res = yield
    api << { op: 'contact_info', ok: true, ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round }
    res
  rescue => e
    api << { op: 'contact_info', ok: false, error: e.message }
    raise
  end

  def api_service_adapter
    ContactService.new(token: @token)
  end
end
