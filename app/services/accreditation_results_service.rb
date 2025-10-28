# frozen_string_literal: true

# Service for posting accreditation results to REPP API
# Used by accr_bot to update user accreditation dates in the registry
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
    @api_url = ENV['BASE_URL'] + ENV['REPP_ACCREDITATION_RESULTS_URL']
    super()
  end

  # Update accreditation date for a user
  # @param username [String] Username to update
  # @param result [Boolean] Accreditation result
  # @return [Hash] Response with success status and data
  def update_accreditation(username, result)
    body = {
      accreditation_result: {
        username: username,
        result: result
      }
    }.to_json

    make_request(:post, @api_url, { headers: @headers, body: body })
  end

  # Check if user is accredited (both tests passed and not expired)
  # @param user [User] User to check
  # @return [Boolean] True if user is accredited
  def user_accredited?(user)
    return false if user.latest_accreditation.nil?

    !user.accreditation_expired?
  end

  # Sync accreditation for a user if they're newly accredited
  # @param user [User] User to sync
  # @return [Hash] Response from API
  def sync_user_accreditation(user)
    return { success: false, message: 'User not accredited' } unless user_accredited?(user)

    update_accreditation(user.username, true)
  end

  # Sync all newly accredited users
  # @return [Integer] Number of users synced
  def sync_all_accredited_users
    synced_count = 0

    User.where(role: 'user').find_each do |user|
      if user_accredited?(user) && should_sync_user?(user)
        result = sync_user_accreditation(user)
        synced_count += 1 if result[:success]
      end
    end

    synced_count
  end

  private

  # Check if user needs to be synced
  # Skip if already synced recently (within last hour)
  def should_sync_user?(_user)
    # Add your logic here - maybe check a flag or timestamp
    # For now, always return true
    true
  end
end
