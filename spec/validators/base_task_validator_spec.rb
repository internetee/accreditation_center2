require 'rails_helper'

RSpec.describe BaseTaskValidator do
  let(:attempt) { instance_double(TestAttempt, vars: { 'token' => 'abc123', 'number' => 42 }) }
  let(:config) { { 'foo' => 'bar' } }
  let(:inputs) { { 'input' => 'value' } }

  describe 'abstract hooks' do
    it 'requires subclasses to implement #api_service_adapter during initialization' do
      expect do
        described_class.new(attempt: attempt, config: config, inputs: inputs)
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#call' do
    subject(:validator) { concrete_class.new(attempt: attempt, config: config, inputs: inputs) }

    let(:concrete_class) do
      Class.new(described_class) do
        def api_service_adapter
          :fake_service
        end
      end
    end

    it 'raises NotImplementedError to force subclasses to override' do
      expect { validator.call }.to raise_error(NotImplementedError)
    end
  end

  describe '#v' do
    subject(:validator) { concrete_class.new(attempt: attempt, config: config, inputs: inputs) }

    let(:concrete_class) do
      Class.new(described_class) do
        def api_service_adapter; end
      end
    end

    it 'fetches attempt vars using stringified keys' do
      expect(validator.send(:v, :token)).to eq('abc123')
      expect(validator.send(:v, 'number')).to eq(42)
    end
  end

  describe '#parse_time' do
    subject(:validator) { concrete_class.new(attempt: attempt, config: config, inputs: inputs) }

    let(:concrete_class) do
      Class.new(described_class) do
        def api_service_adapter; end
      end
    end

    it 'returns nil and logs when parsing fails' do
      allow(Time.zone).to receive(:parse).and_raise(StandardError, 'bad time')
      expect(Rails.logger).to receive(:error).with(/bad time/)

      expect(validator.send(:parse_time, 'invalid')).to be_nil
    end
  end
end
