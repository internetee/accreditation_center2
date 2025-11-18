require 'rails_helper'

RSpec.describe TransferDomainsValidator do
  let(:vars) { { 'xfer_domain' => 'example.ee', 'other_domain' => 'other.ee' } }
  let(:user) { instance_double(User, registrar_name: 'User Registrar') }
  let(:attempt) { instance_double(TestAttempt, vars: vars, user: user) }
  let(:config) { { 'domains' => ['{{xfer_domain}}', '{{other_domain}}'] } }
  let(:inputs) { {} }
  let(:token) { 'api-token' }
  let(:service) { instance_double(DomainService) }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: inputs, token: token) }

  before do
    allow(DomainService).to receive(:new).with(token: token).and_return(service)
  end

  describe '#call' do
    context 'when domains list is empty' do
      let(:config) { { 'domains' => [] } }

      it 'fails immediately' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.transfer_domains_validator.domains_array_missing')
        )
      end
    end

    context 'when all domains transferred successfully' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05, 0.1, 0.15)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(
          success: true,
          registrar: { name: 'User Registrar' }
        )
        allow(service).to receive(:domain_info).with(name: 'other.ee').and_return(
          success: true,
          registrar: { name: 'User Registrar' }
        )
      end

      it 'passes with expected domains evidence' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:evidence][:expected_domains]).to match_array(%w[example.ee other.ee])
        expect(result[:api_audit].size).to eq(2)
        expect(result[:api_audit].all? { |entry| entry[:ok] }).to be(true)
      end
    end

    context 'when a domain is not found' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(success: false)
        allow(service).to receive(:domain_info).with(name: 'other.ee').and_return(success: true, registrar: { name: 'User Registrar' })
      end

      it 'fails with not found error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.transfer_domains_validator.domain_not_found', domain: 'example.ee')
        )
      end
    end

    context 'when registrar info is missing' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(
          success: true,
          registrar: nil
        )
        allow(service).to receive(:domain_info).with(name: 'other.ee').and_return(
          success: true,
          registrar: { name: 'User Registrar' }
        )
      end

      it 'fails with registrar missing error' do
        result = validator.call

        expect(result[:errors]).to include(
          I18n.t('validators.transfer_domains_validator.domain_registrar_info_missing', domain: 'example.ee')
        )
      end
    end

    context 'when registrar does not match user registrar' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(
          success: true,
          registrar: { name: 'Other Registrar' }
        )
        allow(service).to receive(:domain_info).with(name: 'other.ee').and_return(
          success: true,
          registrar: { name: 'User Registrar' }
        )
      end

      it 'fails with registrar mismatch error' do
        result = validator.call

        expect(result[:errors]).to include(
          I18n.t('validators.transfer_domains_validator.domain_registrar_mismatch', domain: 'example.ee')
        )
      end
    end

    context 'when domain_info raises an error' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_raise(StandardError, 'boom')
      end

      it 'records failed audit and treats domain as not found' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.transfer_domains_validator.domain_not_found', domain: 'example.ee')
        )
        expect(result[:api_audit].first[:ok]).to be(false)
        expect(result[:api_audit].first[:error]).to eq('boom')
      end
    end
  end
end
