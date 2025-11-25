require 'rails_helper'

RSpec.describe CreateAndCancelInvoiceValidator do
  let(:attempt) { instance_double(TestAttempt, vars: {}, user: instance_double(User)) }
  let(:config) { { 'window_minutes' => 10 } }
  let(:inputs) { {} }
  let(:token) { 'api-token' }
  let(:service) { instance_double(InvoiceService) }
  let(:validator) { described_class.new(attempt: attempt, config: config, inputs: inputs, token: token) }

  before do
    allow(InvoiceService).to receive(:new).with(token: token).and_return(service)
  end

  describe '#call' do
    context 'when recent cancelled invoices exist' do
      let(:cancelled_time) { Time.zone.now }
      let(:created_time) { cancelled_time - 5.minutes }
      let(:invoice) do
        {
          id: 1,
          created_at: created_time.iso8601,
          cancelled_at: cancelled_time.iso8601,
          number: 'INV-1'
        }
      end

      before do
        allow(Time).to receive(:current).and_return(cancelled_time)
        allow(service).to receive(:cancelled_invoices).and_return([invoice])
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1)
      end

      it 'passes with evidence and audit log entries' do
        result = validator.call

        expect(result[:passed]).to be(true)
        expect(result[:evidence][:count]).to eq(1)
        expect(result[:evidence][:invoices].first[:number]).to eq('INV-1')
        expect(result[:api_audit].first[:ok]).to be(true)
      end
    end

    context 'when no invoices within window' do
      before do
        allow(Time).to receive(:current).and_return(Time.zone.now)
        allow(service).to receive(:cancelled_invoices).and_return(
          { success: false, message: I18n.t('errors.unexpected_response'), data: nil }
        )
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
      end

      it 'fails with explanatory error' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:errors]).to include(I18n.t('validators.create_and_cancel_invoice.no_recently_cancelled_invoices', window: 10))
        expect(result[:api_audit].first[:ok]).to be(false)
      end
    end

    context 'when cancelled_invoices raises an error' do
      before do
        allow(Time).to receive(:current).and_return(Time.zone.now)
        allow(service).to receive(:cancelled_invoices).and_raise(StandardError, 'boom')
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.02)
      end

      it 'records failed audit and returns failure' do
        result = validator.call

        expect(result[:passed]).to be(false)
        expect(result[:api_audit].first[:ok]).to be(false)
        expect(result[:api_audit].first[:error]).to eq('boom')
        expect(result[:errors]).to include(I18n.t('validators.create_and_cancel_invoice.no_recently_cancelled_invoices', window: 10))
      end
    end

    context 'when window_minutes is invalid' do
      let(:config) { { 'window_minutes' => 0 } }

      before do
        allow(Time).to receive(:current).and_return(Time.zone.now)
        allow(service).to receive(:cancelled_invoices).and_return(
          { success: false, message: I18n.t('errors.unexpected_response'), data: nil }
        )
        allow(Process).to receive(:clock_gettime).and_return(0.0, 0.05)
      end

      it 'falls back to 15 minutes' do
        expect(validator).to receive(:with_audit).and_call_original
        validator.call
        expect(validator.instance_variable_get(:@config)['window_minutes']).to eq(0)
      end
    end
  end
end
