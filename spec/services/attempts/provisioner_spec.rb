require 'rails_helper'

RSpec.describe Attempts::Provisioner do
  let(:user) { create(:user) }
  let(:test) { create(:test, :practical) }
  let(:test_attempt) { create(:test_attempt, user: user, test: test) }

  describe '.provision!' do
    context 'when test has no practical tasks' do
      it 'does not call any allocators' do
        expect(Allocators::Registry).not_to receive(:run!)

        described_class.provision!(test_attempt)
      end
    end

    context 'when test has practical tasks without allocators' do
      let!(:task) { create(:practical_task, test: test, active: true, validator: { klass: 'TestValidator' }) }

      it 'does not call any allocators' do
        expect(Allocators::Registry).not_to receive(:run!)

        described_class.provision!(test_attempt)
      end
    end

    context 'when test has practical tasks with allocators' do
      let(:allocator_config1) { { 'name' => 'nameservers', 'config' => { 'count' => 2 } } }
      let(:allocator_config2) { { 'name' => 'domain_pair', 'config' => {} } }
      let(:validator_with_allocators) do
        {
          klass: 'TestValidator',
          config: {},
          allocators: [allocator_config1, allocator_config2]
        }
      end

      let!(:task) { create(:practical_task, test: test, active: true, validator: validator_with_allocators) }

      it 'calls Allocators::Registry.run! for each allocator' do
        expect(Allocators::Registry).to receive(:run!).with(
          name: 'nameservers',
          config: { 'count' => 2 },
          attempt: test_attempt
        )
        expect(Allocators::Registry).to receive(:run!).with(
          name: 'domain_pair',
          config: {},
          attempt: test_attempt
        )

        described_class.provision!(test_attempt)
      end

      it 'uses empty config when allocator config is missing' do
        validator_without_config = {
          klass: 'TestValidator',
          allocators: [{ 'name' => 'nameservers' }]
        }
        task.update!(validator: validator_without_config)

        expect(Allocators::Registry).to receive(:run!).with(
          name: 'nameservers',
          config: {},
          attempt: test_attempt
        )

        described_class.provision!(test_attempt)
      end
    end

    context 'when test has multiple practical tasks' do
      let(:task1_allocator) { { 'name' => 'nameservers', 'config' => {} } }
      let(:task2_allocator) { { 'name' => 'domain_pair', 'config' => {} } }

      let!(:task1) do
        create(:practical_task,
               test: test,
               active: true,
               validator: { klass: 'TestValidator', allocators: [task1_allocator] })
      end
      let!(:task2) do
        create(:practical_task,
               test: test,
               active: true,
               validator: { klass: 'TestValidator2', allocators: [task2_allocator] })
      end

      it 'processes allocators from all tasks' do
        expect(Allocators::Registry).to receive(:run!).with(
          name: 'nameservers',
          config: {},
          attempt: test_attempt
        )
        expect(Allocators::Registry).to receive(:run!).with(
          name: 'domain_pair',
          config: {},
          attempt: test_attempt
        )

        described_class.provision!(test_attempt)
      end
    end

    context 'when test has inactive practical tasks' do
      let(:allocator_config) { { 'name' => 'nameservers', 'config' => {} } }

      let!(:active_task) do
        create(:practical_task,
               test: test,
               active: true,
               validator: { klass: 'TestValidator', allocators: [allocator_config] })
      end
      let!(:inactive_task) do
        create(:practical_task,
               test: test,
               active: false,
               validator: { klass: 'TestValidator2', allocators: [allocator_config] })
      end

      it 'only processes active tasks' do
        expect(Allocators::Registry).to receive(:run!).once.with(
          name: 'nameservers',
          config: {},
          attempt: test_attempt
        )

        described_class.provision!(test_attempt)
      end
    end

    context 'when validator is a JSON string' do
      let(:allocator_config) { { 'name' => 'nameservers', 'config' => {} } }
      let(:validator_json) do
        {
          klass: 'TestValidator',
          allocators: [allocator_config]
        }.to_json
      end

      let!(:task) { create(:practical_task, test: test, active: true, validator: validator_json) }

      it 'parses JSON and processes allocators' do
        expect(Allocators::Registry).to receive(:run!).with(
          name: 'nameservers',
          config: {},
          attempt: test_attempt
        )

        described_class.provision!(test_attempt)
      end
    end
  end
end
