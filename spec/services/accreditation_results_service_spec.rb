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

  describe '#sync_user_accreditation' do
    let(:registrar_name) { 'Registrar A' }
    let(:eligibility) { instance_double(RegistrarAccreditationEligibility) }
    let(:last_theory_test_passed_at) { Time.zone.parse('2026-01-15 10:00:00') }
    let(:expected_body) do
      {
        accreditation_result: {
          registrar_name: registrar_name,
          last_theory_test_passed_at: last_theory_test_passed_at
        }
      }.to_json
    end

    context 'when registrar is not accredited' do
      before do
        allow(RegistrarAccreditationEligibility).to receive(:new).with(registrar_name).and_return(eligibility)
        allow(eligibility).to receive(:accredited?).and_return(false)
      end

      it 'returns error response without making API call' do
        expect(service).not_to receive(:update_accreditation)

        result = service.sync_user_accreditation(registrar_name)

        expect(result).to eq({ success: false, message: 'Registrar not accredited' })
      end
    end

    context 'when registrar is accredited' do
      before do
        allow(RegistrarAccreditationEligibility).to receive(:new).with(registrar_name).and_return(eligibility)
        allow(eligibility).to receive(:accredited?).and_return(true)
        allow(eligibility).to receive(:last_theory_passed_at).and_return(last_theory_test_passed_at)
      end

      it 'posts registrar payload including last theory pass date' do
        stub_request(:post, api_url)
          .with(body: expected_body, headers: headers)
          .to_return(
            status: 200,
            body: {
              code: 1000,
              message: 'Accreditation info successfully added',
              data: {
                registrar_name: registrar_name,
                accreditation_date: last_theory_test_passed_at,
                accreditation_expire_date: (last_theory_test_passed_at + 24.months)
              }
            }.to_json
          )

        expect(service.sync_user_accreditation(registrar_name)).to eq({ success: true, message: 'Accreditation synced successfully' })
      end

      it 'returns error response if API call fails' do
        stub_request(:post, api_url)
          .with(body: expected_body, headers: headers)
          .to_return(status: 404, body: { code: 2303, message: 'Object not found' }.to_json)

        expect(service.sync_user_accreditation(registrar_name)).to eq({ success: false, message: 'Failed to update accreditation' })
      end

      it 'returns error response if API call returns unexpected response' do
        stub_request(:post, api_url)
          .with(body: expected_body, headers: headers)
          .to_return(status: 400, body: { message: 'Registrar name is missing', data: {} }.to_json)

        expect(service.sync_user_accreditation(registrar_name)).to eq({ success: false, message: 'Failed to update accreditation' })
      end

      it 'returns error reponse if StandardError is raised' do
        allow(service).to receive(:update_accreditation).and_raise(StandardError, 'Unexpected error')
        expect(service.sync_user_accreditation(registrar_name))
          .to eq({ success: false, message: "Failed to sync accreditation for registrar 'Registrar A' : Unexpected error" })
      end
    end
  end

  describe '#sync_all_accredited_registrars' do
    let(:registrar_name1) { 'Registrar A' }
    let(:registrar_name2) { 'Registrar B' }
    let(:registrar_name3) { 'Registrar C' }

    before do
      allow(service).to receive(:registrar_names).and_return([registrar_name1, registrar_name2, registrar_name3])
      allow(service).to receive(:should_sync_registrar?).and_return(true)
    end

    it 'syncs only accredited registrars' do
      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar_name1).and_return(true)
      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar_name2).and_return(false)
      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar_name3).and_return(true)

      expect(service).to receive(:sync_user_accreditation).with(registrar_name1).and_return({ success: true })
      expect(service).to receive(:sync_user_accreditation).with(registrar_name3).and_return({ success: true })
      expect(service).not_to receive(:sync_user_accreditation).with(registrar_name2)

      service.sync_all_accredited_registrars
    end

    it 'returns the count of successfully synced registrars' do
      allow(RegistrarAccreditationEligibility).to receive(:accredited?).and_return(true)
      allow(service).to receive(:sync_user_accreditation).with(registrar_name1).and_return({ success: true })
      allow(service).to receive(:sync_user_accreditation).with(registrar_name2).and_return({ success: true })
      allow(service).to receive(:sync_user_accreditation).with(registrar_name3).and_return({ success: false })

      count = service.sync_all_accredited_registrars
      expect(count).to eq(2)
    end

    it 'skips registrars that should not be synced' do
      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar_name1).and_return(true)
      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar_name2).and_return(true)
      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar_name3).and_return(true)
      allow(service).to receive(:should_sync_registrar?).with(registrar_name1).and_return(false)
      allow(service).to receive(:should_sync_registrar?).with(registrar_name2).and_return(true)
      allow(service).to receive(:should_sync_registrar?).with(registrar_name3).and_return(true)

      expect(service).not_to receive(:sync_user_accreditation).with(registrar_name1)
      expect(service).to receive(:sync_user_accreditation).with(registrar_name2).and_return({ success: true })
      expect(service).to receive(:sync_user_accreditation).with(registrar_name3).and_return({ success: true })

      count = service.sync_all_accredited_registrars
      expect(count).to eq(2)
    end
  end
end
