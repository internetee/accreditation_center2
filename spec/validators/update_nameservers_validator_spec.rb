require 'rails_helper'

RSpec.describe UpdateNameserversValidator do
  let(:attempt_vars) do
    {
      'domain1' => 'example1.ee',
      'domain2' => 'example2.ee',
      'ns1_1' => 'ns1.custom.test',
      'ns2_1' => 'ns2.custom.test',
      'ns2_2' => 'ns2.example.test'
    }
  end
  let(:attempt) { instance_double(TestAttempt, vars: attempt_vars) }
  let(:config) do
    {
      'nameservers' => {
        '{{domain1}}' => '{{ns1_1}}',
        '{{domain2}}' => '{{ns2_1}}, {{ns2_2}}'
      }
    }
  end
  let(:inputs) { {} }
  let(:token) { 'api-token' }
  let(:service) { instance_double(DomainService) }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: inputs, token: token) }

  before do
    allow(DomainService).to receive(:new).with(token: token).and_return(service)
  end

  describe '#call' do
    context 'when nameservers config is missing or insufficient' do
      let(:config) { {} }

      it 'fails immediately' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.update_nameservers_validator.nameservers_config_missing_or_empty')
        )
      end
    end

    context 'when both domains have matching nameservers' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05, 0.1, 0.15)
        allow(service).to receive(:domain_info).with(name: 'example1.ee').and_return(
          success: true,
          nameservers: [{ hostname: 'ns1.custom.test' }]
        )
        allow(service).to receive(:domain_info).with(name: 'example2.ee').and_return(
          success: true,
          nameservers: [{ hostname: 'NS2.custom.test' }, { hostname: 'ns2.example.test' }]
        )
      end

      it 'passes with evidence containing expected and actual sets' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:evidence][:dom1][:actual]).to match_array(%w[ns1.custom.test])
        expect(result[:evidence][:dom2][:actual]).to match_array(%w[ns2.custom.test ns2.example.test])
      end
    end

    context 'when domain info is not found' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example1.ee').and_return(success: false)
        allow(service).to receive(:domain_info).with(name: 'example2.ee').and_return(
          success: true,
          nameservers: [{ hostname: 'ns2.custom.test' }, { hostname: 'ns2.example.test' }]
        )
      end

      it 'fails with not found error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.update_nameservers_validator.domain_not_found', domain: 'example1.ee')
        )
      end
    end

    context 'when nameserver sets differ' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05, 0.1, 0.15)
        allow(service).to receive(:domain_info).with(name: 'example1.ee').and_return(
          success: true,
          nameservers: [{ hostname: 'ns1.example.test' }, { hostname: 'ns9.example.test' }]
        )
        allow(service).to receive(:domain_info).with(name: 'example2.ee').and_return(
          success: true,
          nameservers: ['ns2.custom.test', 'ns2.example.test']
        )
      end

      it 'fails with mismatch error for the differing domain' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.update_nameservers_validator.nameservers_mismatch', domain: 'example1.ee')
        )
        expect(result[:errors]).not_to include(
          I18n.t('validators.update_nameservers_validator.nameservers_mismatch', domain: 'example2.ee')
        )
      end
    end

    context 'when domain_info raises an error' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_raise(StandardError, 'boom')
      end

      it 'returns failure with audit error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.update_nameservers_validator.domain_not_found', domain: 'example1.ee')
        )
        expect(result[:api_audit].first[:ok]).to be(false)
        expect(result[:api_audit].first[:error]).to eq('boom')
      end
    end
  end
end
