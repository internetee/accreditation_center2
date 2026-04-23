require 'rails_helper'

RSpec.describe AccreditationSyncJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:registrar_name) { 'Registrar Ltd' }
    let(:service) { instance_double(AccreditationResultsService) }

    before do
      allow(AccreditationResultsService).to receive(:new).and_return(service)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    it 'delegates syncing to AccreditationResultsService' do
      expect(service).to receive(:sync_registrar_accreditation)
        .with(registrar_name)
        .and_return({ success: true, message: 'Accreditation synced successfully' })

      described_class.perform_now(registrar_name)

      expect(Rails.logger).to have_received(:info).with("Successfully synced accreditation for registrar #{registrar_name}")
    end

    it 'logs error when service reports failure' do
      allow(service).to receive(:sync_registrar_accreditation).and_return({ success: false, message: 'boom' })

      described_class.perform_now(registrar_name)

      expect(Rails.logger).to have_received(:error).with(/Failed to sync accreditation for registrar #{registrar_name}: boom/)
    end

    it 'logs unknown error when service returns nil' do
      allow(service).to receive(:sync_registrar_accreditation).and_return(nil)

      described_class.perform_now(registrar_name)

      expect(Rails.logger).to have_received(:error).with(/Failed to sync accreditation for registrar #{registrar_name}: Unknown error/)
    end

    it 'skips when registrar_name is blank' do
      expect(service).not_to receive(:sync_registrar_accreditation)

      described_class.perform_now(nil)

      expect(Rails.logger).to have_received(:error).with('Accreditation sync skipped: registrar_name is blank')
    end

    it 'logs error when service raises exception' do
      allow(service).to receive(:sync_registrar_accreditation).and_raise(StandardError, 'kaboom')

      described_class.perform_now(registrar_name)

      expect(Rails.logger).to have_received(:error).with(/Accreditation sync failed for registrar #{registrar_name}: kaboom/)
    end
  end
end
