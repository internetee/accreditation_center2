require 'rails_helper'

RSpec.describe DeleteDomainVerifiedValidator do
  let(:attempt) { instance_double(TestAttempt, vars: { 'xfer_domain' => 'example.ee' }) }
  let(:config) { {} }
  let(:inputs) { {} }
  let(:token) { 'api-token' }
  let(:service) { instance_double(DomainService) }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: inputs, token: token) }

  before do
    allow(DomainService).to receive(:new).with(token: token).and_return(service)
  end

  describe '#call' do
    context 'when domain exists and is pendingDelete' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_return(
          { success: true, statuses: { pendingDelete: true } }
        )
      end

      it 'passes with evidence and audit log' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:evidence][:domain][:name]).to eq('example.ee')
        expect(result[:evidence][:domain][:statuses]).to include(:pendingDelete)
        expect(result[:api_audit].first[:ok]).to be(true)
      end
    end

    context 'when domain info is missing' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_return(nil)
      end

      it 'fails with not found error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.delete_domain_verified_validator.domain_not_found', domain: 'example.ee')
        )
        expect(result[:api_audit].first[:ok]).to be(false)
      end
    end

    context 'when domain is not pendingDelete' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_return(
          { success: true, statuses: { ok: true } }
        )
      end

      it 'fails with status error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.delete_domain_verified_validator.domain_not_in_pending_delete_status', domain: 'example.ee')
        )
      end
    end

    context 'when custom template is provided' do
      let(:config) { { 'domain' => '{{custom}}' } }
      let(:attempt) { instance_double(TestAttempt, vars: { 'custom' => 'custom.ee' }) }

      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_return(
          { success: true, statuses: { pendingDelete: true } }
        )
      end

      it 'renders template using attempt vars' do
        result = validator.call

        expect(result[:evidence][:domain][:name]).to eq('custom.ee')
      end
    end

    context 'when domain_info raises error' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_raise(StandardError, 'boom')
      end

      it 'records failed audit and returns failure' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:api_audit].first[:ok]).to be(false)
        expect(result[:api_audit].first[:error]).to eq('boom')
        expect(result[:errors]).to include(
          I18n.t('validators.delete_domain_verified_validator.domain_not_found', domain: 'example.ee')
        )
      end
    end
  end
end
