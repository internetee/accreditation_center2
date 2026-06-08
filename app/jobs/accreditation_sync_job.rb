# frozen_string_literal: true

# Background job to sync one registrar accreditation via REPP API
class AccreditationSyncJob < ApplicationJob
  queue_as :default

  # Sync accreditation for a specific registrar and update local dates.
  # @param registrar [Registrar]
  # @param triggering_attempt_id [Integer, nil] completing attempt, passed when sync was enqueued
  def perform(registrar, triggering_attempt_id = nil)
    unless registrar.is_a?(Registrar)
      Rails.logger.error "Accreditation sync skipped: Registrar instance required, got #{registrar.class}"
      return
    end

    triggering_attempt = TestAttempt.find_by(id: triggering_attempt_id) if triggering_attempt_id.present?
    service = AccreditationResultsService.new

    result = service.sync_registrar_accreditation(registrar, triggering_attempt: triggering_attempt)
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
