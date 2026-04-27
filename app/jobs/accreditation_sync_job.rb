# frozen_string_literal: true

# Background job to sync accreditation results to REPP API
class AccreditationSyncJob < ApplicationJob
  queue_as :default

  # Sync accreditation for a specific registrar
  # @param registrar [Registrar]
  def perform(registrar)
    unless registrar.is_a?(Registrar)
      Rails.logger.error "Accreditation sync skipped: Registrar instance required, got #{registrar.class}"
      return
    end

    service = AccreditationResultsService.new

    result = service.sync_registrar_accreditation(registrar)
    message = result&.dig(:message).presence || 'Unknown error'

    unless result&.dig(:success)
      Rails.logger.error "Failed to sync accreditation for registrar #{registrar.name}: #{message}"
      return
    end

    Rails.logger.info "Successfully synced accreditation for registrar #{registrar.name}"
  rescue StandardError => e
    Rails.logger.error "Accreditation sync failed for registrar #{registrar&.name || 'unknown'}: #{e.message}"
  end
end
