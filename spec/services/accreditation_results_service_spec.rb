require 'rails_helper'

RSpec.describe AccreditationResultsService do
  let(:base_url) { 'https://api.example.com' }
  let(:repp_url) { '/repp/v1/registrar/accreditation/push_results' }
  let(:api_url) { base_url + repp_url }
  let(:bot_username) { 'accr_bot' }
  let(:bot_password) { 'secret_password' }

  before do
    ENV['REPP_BASE_URL'] = base_url
    ENV['REPP_ACCREDITATION_RESULTS_URL'] = repp_url
    ENV['ACCR_BOT_USERNAME'] = bot_username
    ENV['ACCR_BOT_PASSWORD'] = bot_password
    ENV['CLIENT_BOT_CERTS_PATH'] = '/path/to/cert'
    ENV['CLIENT_BOT_KEY_PATH'] = '/path/to/key'
  end

  let(:service) { described_class.new }
  let(:headers) { service.instance_variable_get(:@headers) }

  describe '#initialize' do
    it 'sets the API URL correctly' do
      service = described_class.new
      expect(service.instance_variable_get(:@api_url)).to eq(api_url)
    end

    it 'calls super to initialize BotAuthService' do
      expect_any_instance_of(BotAuthService).to receive(:initialize)
      described_class.new
    end
  end

  describe '#sync_registrar_accreditation' do
    let(:registrar) { create(:registrar, name: 'Registrar A') }
    let(:eligibility) { instance_double(RegistrarAccreditationEligibility) }
    let(:notifications_service) { instance_double(RegistrarAccreditationNotificationsService, notify_accreditation_sync: true) }
    let(:last_theory_test_passed_at) { Time.zone.parse('2026-01-15 10:00:00') }

    context 'when registrar is not accredited' do
      before do
        allow(RegistrarAccreditationEligibility).to receive(:new).with(registrar).and_return(eligibility)
        allow(eligibility).to receive(:accredited?).and_return(false)
      end

      it 'returns error response without making API call' do
        expect(service).not_to receive(:update_accreditation)

        result = service.sync_registrar_accreditation(registrar)

        expect(result).to eq({ success: false, message: 'Registrar not accredited' })
      end
    end

    context 'when registrar is invalid' do
      it 'returns error response' do
        expect(service.sync_registrar_accreditation('Registrar A')).to eq({ success: false, message: 'Registrar is required' })
      end
    end

    context 'when registrar is accredited' do
      let(:accreditation_date) { Time.zone.parse('2026-01-15 10:00:00') }
      let(:accreditation_expire_date) { Time.zone.parse('2028-01-15 10:00:00') }

      before do
        allow(RegistrarAccreditationEligibility).to receive(:new).with(registrar).and_return(eligibility)
        allow(eligibility).to receive(:accredited?).and_return(true)
        allow(eligibility).to receive(:last_theory_passed_at).and_return(last_theory_test_passed_at)
        allow(RegistrarAccreditationNotificationsService).to receive(:new).and_return(notifications_service)
      end

      it 'updates registrar accreditation dates after successful sync' do
        allow(service).to receive(:update_accreditation).and_return(
          {
            success: true,
            registrar_name: registrar.name,
            accreditation_date: accreditation_date,
            accreditation_expire_date: accreditation_expire_date
          }
        )

        expect(service.sync_registrar_accreditation(registrar)).to eq({ success: true, message: 'Accreditation synced successfully' })
        expect(registrar.reload.accreditation_date.to_i).to eq(accreditation_date.to_i)
        expect(registrar.accreditation_expire_date.to_i).to eq(accreditation_expire_date.to_i)
        expect(notifications_service).to have_received(:notify_accreditation_sync).with(
          registrar: registrar,
          previous_accreditation_date: nil,
          previous_accreditation_expire_date: nil
        )
      end

      it 'returns error response if API call fails' do
        allow(service).to receive(:update_accreditation).and_return({ success: false, message: 'error' })

        expect(service.sync_registrar_accreditation(registrar)).to eq({ success: false, message: 'Failed to update accreditation' })
      end

      it 'returns error response if API call returns unexpected response' do
        allow(service).to receive(:update_accreditation).and_return(nil)

        expect(service.sync_registrar_accreditation(registrar)).to eq({ success: false, message: 'Failed to update accreditation' })
      end

      it 'returns error reponse if StandardError is raised' do
        allow(service).to receive(:update_accreditation).and_raise(StandardError, 'Unexpected error')
        expect(service.sync_registrar_accreditation(registrar))
          .to eq({ success: false, message: "Failed to sync accreditation for registrar 'Registrar A' : Unexpected error" })
      end
    end
  end

  describe '#sync_all_accredited_registrars' do
    let!(:registrar1) { create(:registrar, name: 'Registrar A') }
    let!(:registrar2) { create(:registrar, name: 'Registrar B') }
    let!(:registrar3) { create(:registrar, name: 'Registrar C') }

    it 'syncs only accredited registrars' do
      allow(service).to receive(:registrars).and_return(Registrar.where(id: [registrar1.id, registrar2.id, registrar3.id]))
      allow(service).to receive(:should_sync_registrar?).and_return(true)

      expect(service).to receive(:sync_registrar_accreditation).with(registrar1).and_return({ success: true })
      expect(service).to receive(:sync_registrar_accreditation).with(registrar2).and_return({ success: false })
      expect(service).to receive(:sync_registrar_accreditation).with(registrar3).and_return({ success: true })

      service.sync_all_accredited_registrars
    end

    it 'returns the count of successfully synced registrars' do
      allow(service).to receive(:registrars).and_return(Registrar.where(id: [registrar1.id, registrar2.id, registrar3.id]))
      allow(service).to receive(:should_sync_registrar?).and_return(true)
      allow(service).to receive(:sync_registrar_accreditation).with(registrar1).and_return({ success: true })
      allow(service).to receive(:sync_registrar_accreditation).with(registrar2).and_return({ success: true })
      allow(service).to receive(:sync_registrar_accreditation).with(registrar3).and_return({ success: false })

      count = service.sync_all_accredited_registrars
      expect(count).to eq(2)
    end

    it 'skips registrars that should not be synced' do
      allow(service).to receive(:registrars).and_return(Registrar.where(id: [registrar1.id, registrar2.id, registrar3.id]))
      allow(service).to receive(:should_sync_registrar?).with(registrar1).and_return(false)
      allow(service).to receive(:should_sync_registrar?).with(registrar2).and_return(true)
      allow(service).to receive(:should_sync_registrar?).with(registrar3).and_return(true)

      expect(service).not_to receive(:sync_registrar_accreditation).with(registrar1)
      expect(service).to receive(:sync_registrar_accreditation).with(registrar2).and_return({ success: true })
      expect(service).to receive(:sync_registrar_accreditation).with(registrar3).and_return({ success: true })

      count = service.sync_all_accredited_registrars
      expect(count).to eq(2)
    end
  end
end
