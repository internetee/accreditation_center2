require 'rails_helper'

RSpec.describe RegisterDomainsValidator do
  let(:attempt) do
    instance_double(
      TestAttempt,
      vars: {
        'domain1' => 'example1.ee',
        'domain2' => 'example2.ee',
        'xfer_domain' => 'example1.ee'
      }
    )
  end
  let(:config) do
    {
      'periods' => {
        '{{domain1}}' => '1y',
        '{{domain2}}' => '2y'
      },
      'enforce_registrant_from_task1' => true
    }
  end
  let(:inputs) { {} }
  let(:token) { 'api-token' }
  let(:service) { instance_double(DomainService) }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: inputs, token: token) }
  let(:org_contact_code) { 'ORG-1' }
  let(:priv_contact_code) { 'PRIV-1' }
  let(:created_time) { Time.zone.parse('2024-01-01 00:00:00') }
  let(:domain_info_template) do
    {
      created_at: created_time,
      expire_time: validator.send(:calculate_expiry, created_time, '1y'),
      registrant: { code: org_contact_code },
      statuses: { ok: true }
    }
  end

  before do
    allow(DomainService).to receive(:new).with(token: token).and_return(service)
    allow(validator).to receive(:v).with(:org_contact_id).and_return(org_contact_code)
    allow(validator).to receive(:v).with(:priv_contact_id).and_return(priv_contact_code)
  end

  describe '#call' do
    context 'when both domains meet requirements' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1, 0.2, 0.3)
        allow(service).to receive(:domain_info).with(name: 'example1.ee').and_return(domain_info_template)
        allow(service).to receive(:domain_info).with(name: 'example2.ee').and_return(
          domain_info_template.merge(
            expire_time: validator.send(:calculate_expiry, created_time, '2y'),
            registrant: { code: priv_contact_code }
          )
        )
      end

      it 'passes with evidence' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:evidence][:dom1][:registrant][:code]).to eq(org_contact_code)
        expect(result[:evidence][:dom2][:registrant][:code]).to eq(priv_contact_code)
      end
    end

    context 'when domain info is missing' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_return(success: false)
      end

      it 'fails with not found error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.register_domains_validator.domain_not_found', domain: 'example1.ee')
        )
      end
    end

    context 'when expiry period mismatch occurs' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1, 0.2, 0.3)
        allow(service).to receive(:domain_info).with(name: 'example1.ee').and_return(
          domain_info_template.merge(expire_time: created_time)
        )
        allow(service).to receive(:domain_info).with(name: 'example2.ee').and_return(
          domain_info_template.merge(
            expire_time: validator.send(:calculate_expiry, created_time, '2y'),
            registrant: { code: priv_contact_code }
          )
        )
      end

      it 'fails with period error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.register_domains_validator.domain_wrong_period', domain: 'example1.ee', period: '1y')
        )
      end
    end

    context 'when registrant is missing' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1, 0.2, 0.3)
        allow(service).to receive(:domain_info).with(name: 'example1.ee').and_return(
          domain_info_template.merge(registrant: nil)
        )
        allow(service).to receive(:domain_info).with(name: 'example2.ee').and_return(
          domain_info_template.merge(registrant: nil)
        )
      end

      it 'fails with missing registrant error' do
        result = validator.call

        expect(result[:errors]).to include(
          I18n.t('validators.register_domains_validator.domain_missing_registrant', domain: 'example1.ee')
        )
        expect(result[:errors]).to include(
          I18n.t('validators.register_domains_validator.domain_missing_registrant', domain: 'example2.ee')
        )
      end
    end

    context 'when registrant code mismatch occurs and enforcement is enabled' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1, 0.2, 0.3)
        allow(service).to receive(:domain_info).with(name: 'example1.ee').and_return(
          domain_info_template.merge(registrant: { code: 'OTHER' })
        )
        allow(service).to receive(:domain_info).with(name: 'example2.ee').and_return(
          domain_info_template.merge(registrant: { code: 'OTHER' })
        )
      end

      it 'fails with registrant errors' do
        result = validator.call

        expect(result[:errors]).to include(
          I18n.t('validators.register_domains_validator.domain_wrong_registrant', domain: 'example1.ee')
        )
        expect(result[:errors]).to include(
          I18n.t('validators.register_domains_validator.domain_wrong_registrant', domain: 'example2.ee')
        )
      end
    end

    context 'when template is customized' do
      let(:config) do
        {
          'periods' => {
            '{{custom1}}' => '1y',
            '{{custom2}}' => '1y'
          }
        }
      end
      let(:attempt) do
        instance_double(TestAttempt, vars: { 'custom1' => 'alpha.ee', 'custom2' => 'beta.ee' })
      end

      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1, 0.2, 0.3)
        allow(service).to receive(:domain_info).with(name: 'alpha.ee').and_return(domain_info_template)
        allow(service).to receive(:domain_info).with(name: 'beta.ee').and_return(
          domain_info_template.merge(registrant: { code: priv_contact_code }, expire_time: validator.send(:calculate_expiry, created_time, '1y'))
        )
      end

      it 'resolves domain names from custom template' do
        expect(validator.call[:passed]).to be(true)
      end
    end

    context 'when domain_info raises' do
      before do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
        allow(service).to receive(:domain_info).and_raise(StandardError, 'boom')
      end

      it 'fails with not found error and audit entry' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(
          I18n.t('validators.register_domains_validator.domain_not_found', domain: 'example1.ee')
        )
        expect(result[:api_audit].first[:ok]).to be(false)
        expect(result[:api_audit].first[:error]).to eq('boom')
      end
    end
  end
end
