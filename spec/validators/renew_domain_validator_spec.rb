require 'rails_helper'

RSpec.describe RenewDomainValidator do
  let(:attempt) { instance_double(TestAttempt, vars: { 'domain1' => 'example.ee' }) }
  let(:config) { { 'domain' => '{{domain1}}', 'years' => 5 } }
  let(:inputs) { {} }
  let(:token) { 'api-token' }
  let(:service) { instance_double(DomainService) }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: inputs, token: token) }
  let(:created_time) { Time.zone.parse('2024-01-01 00:00:00') }
  let(:expire_time) { validator.send(:calculate_expiry, created_time, 5) }

  before do
    allow(DomainService).to receive(:new).with(token: token).and_return(service)
  end

  describe '#call' do
    context 'when domain exists and is renewed correctly' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(
          success: true,
          created_at: created_time,
          expire_time: expire_time
        )
      end

      it 'passes with evidence' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:evidence][:domain][:name]).to eq('example.ee')
        expect(result[:evidence][:domain][:expire_time]).to eq(expire_time)
        expect(result[:api_audit].first[:ok]).to be(true)
      end
    end

    context 'when domain is not found' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(success: false)
      end

      it 'fails with not found error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.renew_domain_validator.domain_not_found', domain: 'example.ee')
        )
      end
    end

    context 'when expire_time is missing' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(
          success: true,
          created_at: created_time,
          expire_time: nil
        )
      end

      it 'fails with missing expire time error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.renew_domain_validator.domain_expire_time_missing', domain: 'example.ee')
        )
      end
    end

    context 'when domain was not renewed' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'example.ee').and_return(
          success: true,
          created_at: created_time,
          expire_time: created_time
        )
      end

      it 'fails with not renewed error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.renew_domain_validator.domain_not_renewed', domain: 'example.ee')
        )
      end
    end

    context 'when domain info request raises' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_raise(StandardError, 'boom')
      end

      it 'returns failure with audit entry' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.renew_domain_validator.domain_not_found', domain: 'example.ee')
        )
        expect(result[:api_audit].first[:ok]).to be(false)
        expect(result[:api_audit].first[:error]).to eq('boom')
      end
    end

    context 'with custom template and years' do
      let(:attempt) { instance_double(TestAttempt, vars: { 'custom_domain' => 'custom.ee' }) }
      let(:config) { { 'domain' => '{{custom_domain}}', 'years' => 2 } }
      let(:expire_time) { validator.send(:calculate_expiry, created_time, 2) }

      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).with(name: 'custom.ee').and_return(
          success: true,
          created_at: created_time,
          expire_time: expire_time
        )
      end

      it 'validates custom settings' do
        result = validator.call
        expect(result[:passed]).to be(true)
        expect(result[:evidence][:domain][:name]).to eq('custom.ee')
        expect(result[:evidence][:domain][:expire_time]).to eq(expire_time)
      end
    end
  end
end
