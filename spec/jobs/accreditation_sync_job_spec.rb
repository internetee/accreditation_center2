require 'rails_helper'

RSpec.describe AccreditationSyncJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:registrar) { create(:registrar, name: 'Registrar Ltd') }
    let(:service) { instance_double(AccreditationResultsService) }

    before do
      allow(AccreditationResultsService).to receive(:new).and_return(service)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    it 'delegates syncing to AccreditationResultsService' do
      expect(service).to receive(:sync_registrar_accreditation)
        .with(registrar)
        .and_return({ success: true, message: 'Accreditation synced successfully' })

      described_class.perform_now(registrar)

      expect(Rails.logger).to have_received(:info).with("Successfully synced accreditation for registrar #{registrar.name}")
    end

    it 'logs error when service reports failure' do
      allow(service).to receive(:sync_registrar_accreditation).and_return({ success: false, message: 'boom' })

      described_class.perform_now(registrar)

      expect(Rails.logger).to have_received(:error).with(/Failed to sync accreditation for registrar #{registrar.name}: boom/)
    end

    it 'logs unknown error when service returns nil' do
      allow(service).to receive(:sync_registrar_accreditation).and_return(nil)

      described_class.perform_now(registrar)

      expect(Rails.logger).to have_received(:error).with(/Failed to sync accreditation for registrar #{registrar.name}: Unknown error/)
    end

    it 'skips when argument is not a Registrar instance' do
      expect(service).not_to receive(:sync_registrar_accreditation)

      described_class.perform_now('Registrar Ltd')

      expect(Rails.logger).to have_received(:error).with('Accreditation sync skipped: Registrar instance required, got String')
    end

    it 'logs error when service raises exception' do
      allow(service).to receive(:sync_registrar_accreditation).and_raise(StandardError, 'kaboom')

      described_class.perform_now(registrar)

      expect(Rails.logger).to have_received(:error).with(/Accreditation sync failed for registrar #{registrar.name}: kaboom/)
    end
  end
end
