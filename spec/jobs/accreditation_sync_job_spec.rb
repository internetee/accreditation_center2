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
      expect(service).to receive(:sync_user_accreditation)
        .with(user)
        .and_return({ success: true })

      described_class.perform_now(user.id)
    end

    it 'logs error when service reports failure' do
      allow(service).to receive(:sync_user_accreditation).and_return({ success: false, message: 'boom' })
      expect(Rails.logger).to receive(:error).with(/Failed to sync accreditation for user #{user.username}: boom/)

      described_class.perform_now(user.id)
    end

    it 'logs error when service raises exception' do
      allow(service).to receive(:sync_user_accreditation).and_raise(StandardError, 'kaboom')
      expect(Rails.logger).to receive(:error).with(/Accreditation sync failed for user ID #{user.id}: kaboom/)

      described_class.perform_now(user.id)
    end
  end
end
