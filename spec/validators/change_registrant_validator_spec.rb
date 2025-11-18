require 'rails_helper'

RSpec.describe ChangeRegistrantValidator do
  let(:attempt_vars) { { 'xfer_domain' => 'target.ee', 'domain1' => 'source.ee' } }
  let(:user) { instance_double(User, email: 'user@example.test') }
  let(:attempt) { instance_double(TestAttempt, vars: attempt_vars, user: user) }
  let(:config) { {} }
  let(:service) { instance_double(DomainService) }
  let(:token) { 'api-token' }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: {}, token: token) }

  before do
    allow(DomainService).to receive(:new).with(token: token).and_return(service)
  end

  describe '#call' do
    context 'when both domains are valid and registrant replaced' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(100.0, 100.5, 200.0, 200.5)
        allow(service).to receive(:domain_info).and_return(
          { success: true, registrant: { code: 'REG1' } },
          { success: true, registrant: { code: 'REG1' } }
        )
      end

      it 'returns a passing result with evidence and audit log' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:score]).to eq(1.0)
        expect(result[:error]).to be_nil
        expect(result[:evidence]).to eq(
          xfer_domain: { name: 'target.ee', registrant_code: 'REG1' },
          source_domain: { name: 'source.ee', registrant_code: 'REG1' }
        )
        expect(result[:api_audit].size).to eq(2)
        expect(result[:api_audit].all? { |entry| entry[:op] == 'domain_info' && entry[:ok] == true }).to be(true)
      end
    end

    context 'when source domain info lookup fails' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(100.0, 100.1)
        allow(service).to receive(:domain_info).and_return(nil)
      end

      it 'fails with descriptive error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.change_registrant.source_domain_not_found', domain: 'source.ee')
        )
      end
    end

    context 'when domain info lookup raises' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(100.0, 100.1, 200.0, 200.1)
        allow(service).to receive(:domain_info).and_raise(StandardError, 'boom')
      end

      it 'records audit errors and returns failure' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.change_registrant.source_domain_not_found', domain: 'source.ee'),
          I18n.t('validators.change_registrant.target_domain_not_found', domain: 'target.ee')
        )
        expect(result[:api_audit].size).to eq(2)
        expect(result[:api_audit].all? { |entry| entry[:ok] == false && entry[:error] == 'boom' }).to be(true)
      end
    end

    context 'when target domain registrant differs from source' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(100.0, 100.1, 200.0, 200.1)
        allow(service).to receive(:domain_info).and_return(
          { success: true, registrant: { code: 'REG1' } },
          { success: true, registrant: { code: 'REG2' } }
        )
      end

      it 'fails with mismatch error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.change_registrant.target_domain_registrant_not_replaced', domain: 'target.ee')
        )
      end
    end

    context 'when custom templates are provided' do
      let(:config) do
        {
          'xfer_domain' => '{{custom_target}}',
          'source_domain' => '{{custom_source}}'
        }
      end
      let(:attempt_vars) do
        {
          'custom_target' => 'custom-target.ee',
          'custom_source' => 'custom-source.ee'
        }
      end

      before do
        allow(Process).to receive(:clock_gettime).and_return(100.0, 100.5, 200.0, 200.5)
        allow(service).to receive(:domain_info).and_return(
          { success: true, registrant: { code: 'REG1' } },
          { success: true, registrant: { code: 'REG1' } }
        )
      end

      it 'renders templates using attempt vars' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:evidence][:xfer_domain][:name]).to eq('custom-target.ee')
        expect(result[:evidence][:source_domain][:name]).to eq('custom-source.ee')
      end
    end

    context 'when registrant data missing' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(100.0, 100.1, 200.0, 200.1)
        allow(service).to receive(:domain_info).and_return(
          { success: true, registrant: {} },
          { success: true, registrant: { code: nil } }
        )
      end

      it 'fails with missing registrant errors' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.change_registrant.source_domain_registrant_missing', domain: 'source.ee')
        )
        expect(result[:errors]).to include(
          I18n.t('validators.change_registrant.target_domain_registrant_missing', domain: 'target.ee')
        )
      end
    end
  end
end
