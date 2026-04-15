require 'rails_helper'

RSpec.describe AccreditationSyncJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:user) { create(:user) }
    let(:service) { instance_double(AccreditationResultsService) }

    before do
      allow(AccreditationResultsService).to receive(:new).and_return(service)
    end

    it 'delegates syncing to AccreditationResultsService' do
      expect(service).to receive(:sync_registrar_accreditation)
        .with(user.registrar_name)
        .and_return({ success: true, message: 'Accreditation synced successfully' })

      described_class.perform_now(user.registrar_name)
    end

    it 'logs error when service reports failure' do
      allow(service).to receive(:sync_registrar_accreditation).and_return({ success: false, message: 'boom' })
      expect(Rails.logger).to receive(:error).with(/Failed to sync accreditation for registrar #{user.registrar_name}: boom/)

      described_class.perform_now(user.registrar_name)
    end

    it 'logs error when service raises exception' do
      allow(service).to receive(:sync_registrar_accreditation).and_raise(StandardError, 'kaboom')
      expect(Rails.logger).to receive(:error).with(/Accreditation sync failed for registrar #{user.registrar_name}: kaboom/)

      described_class.perform_now(user.registrar_name)
    end
  end
end
