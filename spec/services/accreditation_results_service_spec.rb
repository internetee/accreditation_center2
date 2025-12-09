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
    let(:user) { create(:user, username: 'testuser') }
    let(:result) { true }
    let(:expected_body) { { accreditation_result: { username: user.username, result: result } }.to_json }
    let(:accreditation_date) { DateTime.current }

    context 'when user is not accredited' do
      before do
        allow(service).to receive(:user_accredited?).with(user).and_return(false)
      end

      it 'returns error response without making API call' do
        expect(service).not_to receive(:update_accreditation)

        result = service.sync_user_accreditation(user)

        expect(result).to eq({ success: false, message: 'User not accredited' })
      end
    end

    context 'when user is accredited' do
      before do
        allow(service).to receive(:user_accredited?).with(user).and_return(true)
      end

      it 'calls update_accreditation with username and true' do
        stub_request(:post, api_url)
          .with(body: expected_body, headers: headers)
          .to_return(
            status: 200,
            body: {
              code: 1000,
              message: 'Accreditation info successfully added',
              data: {
                username: user.username,
                accreditation_date: accreditation_date,
                accreditation_expire_date: (accreditation_date + 24.months)
              }
            }.to_json
          )

        expect(service.sync_user_accreditation(user)).to eq({ success: true, message: 'Accreditation synced successfully' })
        expect(user.accreditation_date.to_date).to eq(accreditation_date.to_date)
        expect(user.accreditation_expire_date.to_date).to eq((accreditation_date + 24.months).to_date)
      end

      it 'returns error response if API call fails' do
        stub_request(:post, api_url)
          .with(body: expected_body, headers: headers)
          .to_return(status: 404, body: { code: 2303, message: 'Object not found' }.to_json)

        expect(service.sync_user_accreditation(user)).to eq({ success: false, message: 'Failed to update accreditation' })
      end

      it 'returns error response if API call returns unexpected response' do
        stub_request(:post, api_url)
          .with(body: expected_body, headers: headers)
          .to_return(status: 400, body: { message: 'Username is missing', data: {} }.to_json)

        expect(service.sync_user_accreditation(user)).to eq({ success: false, message: 'Failed to update accreditation' })
      end

      it 'returns error reponse if StandardError is raised' do
        allow(service).to receive(:update_accreditation).and_raise(StandardError, 'Unexpected error')
        expect(service.sync_user_accreditation(user)).to eq({ success: false, message: 'Failed to sync accreditation for user testuser: Unexpected error' })
      end
    end
  end

  describe '#sync_all_accredited_users' do
    let!(:accredited_user1) { create(:user, role: 'user', username: 'user1') }
    let!(:accredited_user2) { create(:user, role: 'user', username: 'user2') }
    let!(:non_accredited_user) { create(:user, role: 'user', username: 'user3') }
    let!(:admin_user) { create(:user, role: 'admin', username: 'admin') }

    before do
      allow(service).to receive(:user_accredited?).with(accredited_user1).and_return(true)
      allow(service).to receive(:user_accredited?).with(accredited_user2).and_return(true)
      allow(service).to receive(:user_accredited?).with(non_accredited_user).and_return(false)
      allow(service).to receive(:should_sync_user?).and_return(true)
    end

    it 'only processes users with role "user"' do
      stub_request(:post, api_url)
        .to_return(status: 200, body: { code: 1000, message: 'Accreditation info successfully added', data: { result: true } }.to_json)

      expect(service).to receive(:user_accredited?).with(accredited_user1)
      expect(service).to receive(:user_accredited?).with(accredited_user2)
      expect(service).to receive(:user_accredited?).with(non_accredited_user)
      expect(service).not_to receive(:user_accredited?).with(admin_user)

      service.sync_all_accredited_users
    end

    it 'syncs only accredited users' do
      expect(service).to receive(:sync_user_accreditation).with(accredited_user1).and_return({ success: true })
      expect(service).to receive(:sync_user_accreditation).with(accredited_user2).and_return({ success: true })
      expect(service).not_to receive(:sync_user_accreditation).with(non_accredited_user)

      service.sync_all_accredited_users
    end

    it 'returns the count of successfully synced users' do
      allow(service).to receive(:sync_user_accreditation).with(accredited_user1).and_return({ success: true })
      allow(service).to receive(:sync_user_accreditation).with(accredited_user2).and_return({ success: true })

      count = service.sync_all_accredited_users
      expect(count).to eq(2)
    end

    it 'only counts successful syncs' do
      allow(service).to receive(:sync_user_accreditation).with(accredited_user1).and_return({ success: true })
      allow(service).to receive(:sync_user_accreditation).with(accredited_user2).and_return({ success: false, message: 'Error' })

      count = service.sync_all_accredited_users
      expect(count).to eq(1)
    end

    context 'when should_sync_user? returns false' do
      before do
        allow(service).to receive(:should_sync_user?).with(accredited_user1).and_return(false)
        allow(service).to receive(:should_sync_user?).with(accredited_user2).and_return(true)
      end

      it 'skips users that should not be synced' do
        expect(service).not_to receive(:sync_user_accreditation).with(accredited_user1)
        expect(service).to receive(:sync_user_accreditation).with(accredited_user2).and_return({ success: true })

        count = service.sync_all_accredited_users
        expect(count).to eq(1)
      end
    end
  end
end
