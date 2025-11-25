require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  routes { Rails.application.routes }

  describe '#assign_test_attempts' do
    let(:user) { build_stubbed(:user) }
    let(:service) { instance_double(Attempts::AutoAssign) }
    let(:flash_hash) { ActionDispatch::Flash::FlashHash.new }

    before do
      allow(controller).to receive(:flash).and_return(flash_hash)
      allow(Attempts::AutoAssign).to receive(:new).with(user: user).and_return(service)
    end

    it 'does nothing when there are no failures' do
      allow(service).to receive(:call).and_return([])

      expect(AccreditationMailer).not_to receive(:assignment_failed)
      controller.send(:assign_test_attempts, user)

      expect(flash_hash[:alert]).to be_nil
    end

    it 'notifies coordinators when failures occur' do
      failures = [Attempts::AutoAssign::Failure.new(test_type: 'theoretical', error_message: 'boom')]
      mailer = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      allow(service).to receive(:call).and_return(failures)
      allow(AccreditationMailer).to receive(:assignment_failed).with(user, failures).and_return(mailer)

      controller.send(:assign_test_attempts, user)

      expect(flash_hash[:alert]).to eq(I18n.t('users.sessions.assignment_failed'))
      expect(AccreditationMailer).to have_received(:assignment_failed).with(user, failures)
    end
  end
end
