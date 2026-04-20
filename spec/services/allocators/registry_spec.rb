require 'rails_helper'

RSpec.describe Allocators::Registry do
  describe '.run!' do
    let(:attempt) { instance_double(TestAttempt) }
    let(:config) { { 'foo' => 'bar' } }

    it 'instantiates and calls the mapped allocator' do
      allocator_class = class_double('Allocators::DomainPair').as_stubbed_const
      allocator_instance = instance_double('Allocators::DomainPair')

      expect(allocator_class).to receive(:new).with(config: config, attempt: attempt).and_return(allocator_instance)
      expect(allocator_instance).to receive(:call)

      described_class.run!(name: 'domain_pair', config: config, attempt: attempt)
    end

    it 'raises for unknown allocator names' do
      expect do
        described_class.run!(name: 'unknown_allocator', config: config, attempt: attempt)
      end.to raise_error('Unknown allocator: unknown_allocator')
    end
  end
end
