require 'rails_helper'

RSpec.describe ExpiryCheckJob, type: :job do
  describe '#perform' do
    let(:service) { instance_double(RegistrarAccreditationNotificationsService) }
    let(:reference_date) { Date.new(2026, 4, 27) }

    before do
      allow(RegistrarAccreditationNotificationsService).to receive(:new).and_return(service)
      allow(Rails.logger).to receive(:error)
    end

    it 'delegates expiry processing to RegistrarAccreditationNotificationsService' do
      expect(service).to receive(:notify_daily_expiry_checks).with(reference_date: reference_date)

      described_class.perform_now(reference_date)
    end

    it 'logs and swallows errors from the notification service' do
      allow(service).to receive(:notify_daily_expiry_checks).and_raise(StandardError, 'boom')

      expect { described_class.perform_now(reference_date) }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with("Daily expiry check failed for #{reference_date}: boom")
    end
  end
end
