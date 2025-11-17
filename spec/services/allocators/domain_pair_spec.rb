require 'rails_helper'

RSpec.describe Allocators::DomainPair do
  let(:attempt) { instance_double(TestAttempt, id: 123, vars: vars) }
  let(:vars) { {} }
  let(:config) { {} }
  let(:allocator) { described_class.new(config: config, attempt: attempt) }

  before do
    allow(attempt).to receive(:merge_vars!) do |hash|
      vars.merge!(hash)
      hash
    end
    allow(SecureRandom).to receive(:alphanumeric).and_return('abcdef')
  end

  describe '#call' do
    context 'when variables already set' do
      let(:vars) { { 'domain1' => 'existing1.ee', 'domain2' => 'existing2.ee' } }

      it 'does nothing to keep idempotency' do
        expect(attempt).not_to receive(:merge_vars!)
        allocator.call
      end
    end

    context 'with default configuration' do
      it 'creates ASCII and IDN domains with default keys' do
        expect(SimpleIDN).to receive(:to_ascii).and_call_original

        allocator.call

        expect(vars).to include(
          'domain1' => 'gransytest-123-abcdef.ee',
          'domain2' => 'gränsytest-123-abcdef.ee',
          'domain2_ascii' => 'xn--grnsytest-123-abcdef-czb.ee'
        )
      end
    end

    context 'with export overrides' do
      let(:config) do
        {
          'export' => {
            'domain1' => 'ascii_domain',
            'domain2' => 'unicode_domain',
            'domain2_ascii' => 'unicode_domain_ascii'
          }
        }
      end

      it 'uses the specified export keys' do
        allocator.call

        expect(vars.keys).to contain_exactly('ascii_domain', 'unicode_domain', 'unicode_domain_ascii')
      end
    end

    context 'with custom bases and TLD' do
      let(:config) do
        {
          'base1' => 'customascii',
          'base2' => 'custömidn',
          'tld' => 'test'
        }
      end

      it 'uses provided base labels and TLD' do
        allocator.call

        expect(vars['domain1']).to eq('customascii-123-abcdef.test')
        expect(vars['domain2']).to eq('custömidn-123-abcdef.test')
        expect(vars['domain2_ascii']).to eq(SimpleIDN.to_ascii(vars['domain2']))
      end
    end

    context 'with Faker disabled (default)' do
      it 'uses deterministic fallback labels' do
        allocator.call
        expect(vars['domain1']).to start_with('gransytest-123-abcdef')
        expect(vars['domain2']).to start_with('gränsytest-123-abcdef')
      end
    end

    context 'with Faker enabled but missing' do
      let(:config) { { 'use_faker' => true } }

      it 'falls back to deterministic labels' do
        hide_const('Faker') if defined?(Faker)

        allocator.call
        expect(vars['domain1']).to start_with('gransytest-')
        expect(vars['domain2']).to start_with('gränsytest-')
      end
    end

    context 'with Faker enabled and defined' do
      let(:config) { { 'use_faker' => true } }

      before do
        stub_const('Faker', Module.new)
        internet_module = Module.new do
          def self.domain_word
            'CustomWord'
          end
        end
        stub_const('Faker::Internet', internet_module)
      end

      it 'uses Faker provided labels' do
        allow(SimpleIDN).to receive(:to_ascii).and_call_original

        allocator.call

        expect(vars['domain1']).to start_with('customword')
        expect(vars['domain2']).to include('ä').or include('õ').or include('ü').or include('ö')
      end
    end
  end
end
