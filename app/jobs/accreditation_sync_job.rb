# frozen_string_literal: true

# Background job to sync accreditation results to REPP API
class AccreditationSyncJob < ApplicationJob
  queue_as :default

  # Sync accreditation for a specific user
  # @param user_id [Integer] ID of the user to sync
  def perform(user_id)
    user = User.find(user_id)
    service = AccreditationResultsService.new

    result = service.sync_user_accreditation(user)

    if result[:success]
      Rails.logger.info "Successfully synced accreditation for user #{user.username}"
    else
      Rails.logger.error "Failed to sync accreditation for user #{user.username}: #{result[:message]}"
    end
  rescue StandardError => e
    Rails.logger.error "Accreditation sync failed for user ID #{user_id}: #{e.message}"
  end
end
