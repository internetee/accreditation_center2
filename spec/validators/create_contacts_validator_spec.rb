require 'rails_helper'

RSpec.describe CreateContactsValidator do
  let(:attempt) { instance_double(TestAttempt, vars: {}) }
  let(:config) { { 'window_minutes' => 15 } }
  let(:inputs) { { 'org_contact_id' => 'ORG-1', 'priv_contact_id' => 'PRIV-1' } }
  let(:token) { 'api-token' }
  let(:service) { instance_double(ContactService) }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: inputs, token: token) }
  let(:contact_template) do
    {
      code: 'C-1',
      name: 'Contact',
      ident: { type: 'org' },
      phone: '+372123456',
      email: 'contact@example.test',
      created_at: Time.current.iso8601
    }
  end

  before do
    allow(ContactService).to receive(:new).with(token: token).and_return(service)
  end

  describe '#call' do
    context 'when both contacts are valid and recent' do
      before do
        allow(service).to receive(:contact_info).with(id: 'ORG-1').and_return(contact_template.merge(ident: { type: 'org' }))
        allow(service).to receive(:contact_info).with(id: 'PRIV-1').and_return(contact_template.merge(ident: { type: 'priv' }))
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1, 0.2, 0.3)
      end

      it 'passes and exports contact ids' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:score]).to eq(1.0)
        expect(result[:errors]).to be_nil
        expect(result[:export_vars]).to eq({ 'org_contact_id' => 'ORG-1', 'priv_contact_id' => 'PRIV-1' })
        expect(result[:api_audit].size).to eq(2)
        expect(result[:api_audit].all? { |entry| entry[:ok] }).to be(true)
      end
    end

    context 'when contacts are missing' do
      before do
        allow(service).to receive(:contact_info).with(id: 'ORG-1').and_return(nil)
        allow(service).to receive(:contact_info).with(id: 'PRIV-1').and_return(nil)
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05, 0.1, 0.15)
      end

      it 'fails with not found errors' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.organization_contact_not_found'))
        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.private_contact_not_found'))
      end
    end

    context 'when contact types mismatch' do
      before do
        allow(service).to receive(:contact_info).with(id: 'ORG-1').and_return(contact_template.merge(ident: { type: 'priv' }))
        allow(service).to receive(:contact_info).with(id: 'PRIV-1').and_return(contact_template.merge(ident: { type: 'org' }))
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05, 0.1, 0.15)
      end

      it 'fails with type mismatch errors' do
        result = validator.call

        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.org_type_mismatch'))
        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.priv_type_mismatch'))
      end
    end

    context 'when required fields are missing' do
      let(:incomplete_contact) { contact_template.merge(phone: nil) }

      before do
        allow(service).to receive(:contact_info).with(id: 'ORG-1').and_return(incomplete_contact.merge(ident: { type: 'org' }))
        allow(service).to receive(:contact_info).with(id: 'PRIV-1').and_return(incomplete_contact.merge(ident: { type: 'priv' }))
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05, 0.1, 0.15)
      end

      it 'fails with missing fields errors' do
        result = validator.call

        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.org_required_fields_missing'))
        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.priv_required_fields_missing'))
      end
    end

    context 'when contacts are not recent' do
      before do
        stale_contact = contact_template.merge(created_at: (Time.zone.now - 1.day).iso8601)
        allow(service).to receive(:contact_info).with(id: 'ORG-1').and_return(stale_contact.merge(ident: { type: 'org' }))
        allow(service).to receive(:contact_info).with(id: 'PRIV-1').and_return(stale_contact.merge(ident: { type: 'priv' }))
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05, 0.1, 0.15)
        allow(Time).to receive(:current).and_return(Time.zone.now)
      end

      it 'fails with not recent errors' do
        result = validator.call

        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.org_contact_not_recent'))
        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.priv_contact_not_recent'))
      end
    end

    context 'when service raises during audit' do
      before do
        allow(service).to receive(:contact_info).with(id: 'PRIV-1').and_return(contact_template.merge(ident: { type: 'priv' }))
        allow(service).to receive(:contact_info).with(id: 'ORG-1').and_raise(StandardError, 'boom')
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
      end

      it 'propagates error with failed audit entry' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(I18n.t('validators.create_contacts_validator.organization_contact_not_found'))
        expect(result[:api_audit].first[:ok]).to be(false)
        expect(result[:api_audit].first[:error]).to eq('boom')
      end
    end
  end
end
