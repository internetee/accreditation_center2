require 'rails_helper'

RSpec.describe Allocators::DomainTransferSeed do
  let(:attempt) { instance_double(TestAttempt, id: 42) }
  let(:vars) { {} }
  let(:config) { {} }
  let(:allocator) { described_class.new(config: config, attempt: attempt) }
  let(:service) { instance_double(ReppDomainService) }
  let(:default_response) do
    {
      success: true,
      domain: { name: 'example.ee', transfer_code: 'secret-code' }
    }
  end

  before do
    ENV['ACCR_BOT_CONTACT_CODE'] = 'ACCR-BOT'
    allow(attempt).to receive(:vars).and_return(vars)
    allow(attempt).to receive(:merge_vars!) { |hash| vars.merge!(hash) }
    allow(SecureRandom).to receive(:hex).and_return('manualcode', 'abc123')
    allow(ReppDomainService).to receive(:new).and_return(service)
    allow(service).to receive(:create_domain).and_return(default_response)
  end

  after { ENV.delete('ACCR_BOT_CONTACT_CODE') }

  describe '#call' do
    it 'raises when bot contact code missing' do
      ENV['ACCR_BOT_CONTACT_CODE'] = nil
      expect { allocator.call }.to raise_error('Allocator domain_transfer_seed: missing bot contact code')
    end

    it 'skips provisioning when vars already populated' do
      vars['xfer_domain'] = 'existing'
      vars['xfer_code'] = 'code'
      expect(service).not_to receive(:create_domain)
      allocator.call
    end

    it 'creates domain and exports values by default' do
      expect(service).to receive(:create_domain).with(
        hash_including(
          name: match(/seed-42-1-abc123\.ee/),
          registrant: 'ACCR-BOT',
          transfer_code: 'manualcode'
        )
      ).and_return(default_response)

      allocator.call

      expect(vars).to include(
        'xfer_domain' => 'example.ee',
        'xfer_code' => 'secret-code',
        'xfer_domain1' => 'example.ee',
        'xfer_code1' => 'secret-code'
      )
    end

    it 'omits manual code when auto_transfer_code is true' do
      config['auto_transfer_code'] = true
      expect(service).to receive(:create_domain).with(
        hash_including(transfer_code: nil)
      ).and_return(default_response)
      allocator.call
    end

    it 'exports multiple numbered keys when count > 1' do
      config['count'] = 2
      allow(SecureRandom).to receive(:hex).and_return('manualcode', 'abc123', 'def456')
      allow(service).to receive(:create_domain).and_return(
        { success: true, domain: { name: 'example1.ee', transfer_code: 'code1' } },
        { success: true, domain: { name: 'example2.ee', transfer_code: 'code2' } }
      )

      allocator.call

      expect(vars).to include(
        'xfer_domain1' => 'example1.ee',
        'xfer_code1' => 'code1',
        'xfer_domain2' => 'example2.ee',
        'xfer_code2' => 'code2',
        'xfer_domain' => 'example1.ee',
        'xfer_code' => 'code1'
      )
    end

    it 'supports custom export keys' do
      config['export'] = { 'domain_key' => 'domain_export', 'code_key' => 'code_export' }
      allocator.call
      expect(vars.keys).to include('domain_export', 'code_export', 'domain_export1', 'code_export1')
    end

    it 'uses deterministic label when Faker disabled' do
      expect(service).to receive(:create_domain).with(
        hash_including(name: match(/seed-42-1-abc123\.ee/))
      ).and_return(default_response)
      allocator.call
    end

    it 'falls back to deterministic label when Faker missing' do
      config['use_faker'] = true
      hide_const('Faker') if defined?(Faker)
      expect(service).to receive(:create_domain).with(
        hash_including(name: match(/seed-42-1-abc123\.ee/))
      ).and_return(default_response)
      allocator.call
    end

    it 'uses Faker label when available' do
      config['use_faker'] = true
      stub_const('Faker', Module.new)
      internet_module = Module.new do
        def self.domain_word
          'CustomSeed'
        end
      end
      stub_const('Faker::Internet', internet_module)

      expect(service).to receive(:create_domain).with(
        hash_including(name: match(/customseed-42-1/))
      ).and_return(default_response)
      allocator.call
    end
  end
end
