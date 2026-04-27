# frozen_string_literal: true

# Background job that runs the daily registrar accreditation expiry checks.
class ExpiryCheckJob < ApplicationJob
  queue_as :default

  def perform(reference_date = Time.zone.today)
    RegistrarAccreditationNotificationsService.new.notify_daily_expiry_checks(reference_date: reference_date)
  rescue StandardError => e
    Rails.logger.error("Daily expiry check failed for #{reference_date}: #{e.message}")
  end
end
