# frozen_string_literal: true

# Service for posting accreditation results to REPP API
# Used by accr_bot to update registrar accreditation dates in the registry
#
# SECURITY:
# This service authenticates using accr_bot credentials (ACCR_BOT_USERNAME, ACCR_BOT_PASSWORD)
# The credentials are loaded from application.yml and should be secured in production.
# SSL client certificates are used for additional security (CLIENT_BOT_CERTS_PATH, CLIENT_BOT_KEY_PATH)
#
# Only the accr_bot user can update accreditation dates in the registry.
# The REPP API endpoint /repp/v1/registrar/accreditation/push_results requires:
# - Valid accr_bot username and password
# - Valid SSL client certificate
# - Shared secret key authentication (configured on registry side)
class AccreditationResultsService < BotAuthService
  # Initialize the service with accr_bot credentials
  # credentials are loaded from application.yml
  def initialize
    @api_url = ENV['REPP_BASE_URL'] + ENV['REPP_ACCREDITATION_RESULTS_URL']
    super()
  end

  # Sync accreditation for a registrar if they're newly accredited
  # @param registrar_name [String] Registrar name to sync
  # @return [Hash] Response from API
  def sync_registrar_accreditation(registrar_name)
    eligibility = RegistrarAccreditationEligibility.new(registrar_name)
    return { success: false, message: 'Registrar not accredited' } unless eligibility.accredited?

    result = update_accreditation(
      registrar_name,
      last_theory_test_passed_at: eligibility.last_theory_passed_at
    )

    return { success: false, message: 'Failed to update accreditation' } if result.nil? || result[:success] == false

    { success: true, message: 'Accreditation synced successfully' }
  rescue StandardError => e
    { success: false, message: "Failed to sync accreditation for registrar '#{registrar_name}' : #{e.message}" }
  end

  # Sync all accredited registrars
  # @return [Integer] Number of registrars synced
  def sync_all_accredited_registrars
    synced_count = 0

    registrar_names.each do |registrar_name|
      next unless RegistrarAccreditationEligibility.accredited?(registrar_name)
      next unless should_sync_registrar?(registrar_name)

      result = sync_registrar_accreditation(registrar_name)
      synced_count += 1 if result[:success]
    end

    synced_count
  end

  private

  def registrar_names
    User.not_admin
        .pluck(:registrar_name)
        .filter_map { |name| name.to_s.strip.presence }
        .uniq
  end

  # Update accreditation date for a registrar
  # @param registrar_name [String] Registrar name to update
  # @param result [Boolean] Accreditation result
  # @return [Hash] Response with success status and data
  def update_accreditation(registrar_name, last_theory_test_passed_at: nil)
    body = {
      accreditation_result: {
        registrar_name: registrar_name,
        last_theory_test_passed_at: last_theory_test_passed_at
      }
    }.to_json

    result = make_request(:post, @api_url, { headers: @headers, body: body })
    return result unless result[:success]

    data = result[:data]

    if data.is_a?(Hash) && data.key?('registrar_name')
      symbolize_keys_deep(data)
    else
      error_response(nil, I18n.t('errors.unexpected_response'))
    end
  end

  def should_sync_registrar?(_registrar_name)
    # Placeholder for deduping/rate-limit logic if needed later.
    true
  end
end
