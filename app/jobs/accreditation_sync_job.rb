# frozen_string_literal: true

# Background job to sync accreditation results to REPP API
class AccreditationSyncJob < ApplicationJob
  queue_as :default

  # Sync accreditation for a specific registrar
  # @param registrar_name [String] Name of the registrar to sync
  def perform(registrar_name)
    service = AccreditationResultsService.new

    result = service.sync_registrar_accreditation(registrar_name)

    if result.nil? || result[:success] == false
      Rails.logger.error "Failed to sync accreditation for registrar #{registrar_name}: #{result[:message]}"
      return
    end

    Rails.logger.info "Successfully synced accreditation for registrar #{registrar_name}"
  rescue StandardError => e
    Rails.logger.error "Accreditation sync failed for registrar #{registrar_name}: #{e.message}"
  end
end
