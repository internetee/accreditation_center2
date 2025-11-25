require 'rails_helper'

RSpec.describe Allocators::Nameservers do
  let(:attempt) { instance_double(TestAttempt, id: 1) }
  let(:vars) { {} }
  let(:config) { {} }
  let(:allocator) { described_class.new(config: config, attempt: attempt) }

  before do
    allow(attempt).to receive(:vars).and_return(vars)
    allow(attempt).to receive(:merge_vars!) { |hash| vars.merge!(hash) }
  end

  describe '#call' do
    context 'when first pair already exists' do
      let(:vars) { { 'ns1_1' => 'ns1.example.net', 'ns2_1' => 'ns2.example.org' } }

      it 'returns without creating additional values' do
        expect(attempt).not_to receive(:merge_vars!)
        allocator.call
      end
    end

    context 'with default configuration' do
      before { allow_any_instance_of(described_class).to receive(:rand).and_return(3) }

      it 'exports two pairs of nameservers with fallback suffixes' do
        allocator.call

        expect(vars.keys).to contain_exactly('ns1_1', 'ns2_1', 'ns1_2', 'ns2_2')
        vars.each_value do |value|
          expect(value).to start_with('ns3.')
        end
        expect(vars['ns1_1']).to end_with('.example.net')
        expect(vars['ns2_1']).to end_with('.example.org')
      end
    end

    context 'with custom export prefixes and count' do
      let(:config) do
        {
          'export' => { 'd1_prefix' => 'primary_', 'd2_prefix' => 'backup_' },
          'count' => 3
        }
      end

      it 'uses the provided prefixes and count' do
        allocator.call

        expect(vars.keys).to match_array(
          %w[primary_1 backup_1 primary_2 backup_2 primary_3 backup_3]
        )
      end
    end

    context 'when count is invalid' do
      let(:config) { { 'count' => 0 } }

      it 'falls back to default count' do
        allocator.call
        expect(vars.keys.length).to eq(4)
      end
    end

    context 'with Faker enabled but undefined' do
      let(:config) { { 'use_faker' => true } }

      it 'uses deterministic fallback suffixes' do
        hide_const('Faker') if defined?(Faker)
        allocator.call
        expect(vars.values).to all(include('example'))
      end
    end

    context 'with Faker enabled and defined' do
      let(:config) { { 'use_faker' => true } }

      before do
        stub_const('Faker', Module.new)
        internet_module = Module.new do
          def self.domain_name
            'CustomDomain.test'
          end
        end
        stub_const('Faker::Internet', internet_module)
      end

      it 'uses Faker-provided domain names as suffixes' do
        allocator.call

        expect(vars['ns1_1']).to include('customdomain.test')
        expect(vars['ns2_1']).to include('customdomain.test')
      end
    end
  end
end
