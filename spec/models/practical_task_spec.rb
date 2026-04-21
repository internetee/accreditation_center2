require 'rails_helper'

RSpec.describe PracticalTask, type: :model do
  let(:test_record) { create(:test, :practical) }

  describe 'associations' do
    it 'belongs to test' do
      task = create(:practical_task, test: test_record)
      expect(task.test).to eq(test_record)
      expect(test_record.practical_tasks).to include(task)
    end

    it 'has many practical_task_results' do
      task = create(:practical_task, test: test_record)
      attempt1 = create(:test_attempt, test: test_record)
      attempt2 = create(:test_attempt, test: test_record)
      result1 = create(:practical_task_result, practical_task: task, test_attempt: attempt1)
      result2 = create(:practical_task_result, practical_task: task, test_attempt: attempt2)

      expect(task.practical_task_results).to include(result1, result2)
    end
  end

  describe 'validations' do
    it 'validates display_order presence and numericality > 0' do
      task = build(:practical_task, test: test_record, display_order: nil)
      expect(task.valid?).to be(false)
      expect(task.errors[:display_order]).to be_present

      task = build(:practical_task, test: test_record, display_order: 0)
      expect(task.valid?).to be(false)
      expect(task.errors[:display_order]).to be_present

      task = build(:practical_task, test: test_record, display_order: 2)
      expect(task.valid?).to be(true)
    end
  end

  describe 'scopes' do
    it 'orders by display_order' do
      t1 = create(:practical_task, test: test_record, display_order: 3)
      t2 = create(:practical_task, test: test_record, display_order: 1)
      t3 = create(:practical_task, test: test_record, display_order: 2)

      expect(PracticalTask.ordered.map(&:id)).to eq([t2.id, t3.id, t1.id])
    end

    it 'filters active tasks' do
      active_task = create(:practical_task, test: test_record, active: true)
      inactive_task = create(:practical_task, test: test_record, active: false)

      expect(PracticalTask.active).to include(active_task)
      expect(PracticalTask.active).not_to include(inactive_task)
    end
  end

  describe 'translator fields' do
    it 'responds to translated accessors' do
      task = create(:practical_task, test: test_record, title_et: 'Pealkiri', title_en: 'Title', body_et: 'Keha', body_en: 'Body')
      expect(task.title_et).to eq('Pealkiri')
      expect(task.title_en).to eq('Title')
      expect(task.body_et).to eq('Keha')
      expect(task.body_en).to eq('Body')
    end
  end

  describe 'validator configuration helpers' do
    context 'when validator is a Hash' do
      let(:validator_hash) do
        {
          klass: 'DnssecValidator',
          config: { allow_algo: [8] },
          input_fields: %w[domain_name ds_record],
          depends_on_task_ids: [1, 2]
        }
      end

      it 'parses vconf with indifferent access and exposes helpers' do
        task = create(:practical_task, test: test_record, validator: validator_hash)

        expect(task.vconf[:klass]).to eq('DnssecValidator')
        expect(task.klass_name).to eq('DnssecValidator')
        expect(task.conf).to eq({ 'allow_algo' => [8] })
        expect(task.input_fields).to match_array(%w[domain_name ds_record])
        expect(task.deps).to match_array([1, 2])
      end
    end

    context 'when validator is a JSON string' do
      let(:validator_json) do
        {
          klass: 'ContactValidator',
          config: { required: ['name'] },
          input_fields: ['name'],
          depends_on_task_ids: []
        }.to_json
      end

      it 'parses JSON string and exposes helpers' do
        task = create(:practical_task, test: test_record, validator: validator_json)
        expect(task.klass_name).to eq('ContactValidator')
        expect(task.conf).to eq({ 'required' => ['name'] })
        expect(task.input_fields).to eq(['name'])
        expect(task.deps).to eq([])
      end
    end

    context 'when validator is nil or blank' do
      it 'returns empty config and arrays' do
        task = create(:practical_task, test: test_record, validator: nil)
        expect(task.vconf).to eq({}.with_indifferent_access)
        expect(task.klass_name).to be_nil
        expect(task.conf).to eq({})
        expect(task.input_fields).to eq([])
        expect(task.deps).to eq([])
      end
    end
  end

  describe 'auto deactivation' do
    it 'deactivates when validator missing' do
      task = create(:practical_task, test: test_record, validator: nil)
      # callback runs before validation, so active should be false
      expect(task.active).to be(false)
    end

    it 'deactivates when validator has no klass' do
      task = create(:practical_task, test: test_record, validator: { config: {} })
      expect(task.active).to be(false)
    end

    it 'remains active when validator has klass' do
      task = create(:practical_task, test: test_record, validator: { klass: 'AnyValidator' })
      expect(task.active).to be(true)
    end
  end

  describe 'positioned functionality' do
    it 'orders tasks within the same test by display_order' do
      other_test = create(:test, :practical)
      a = create(:practical_task, test: test_record, display_order: 1)
      b = create(:practical_task, test: test_record, display_order: 2)
      c = create(:practical_task, test: other_test, display_order: 1)

      expect(test_record.practical_tasks.ordered).to eq([a, b])
      expect(other_test.practical_tasks.ordered).to eq([c])
    end
  end
end
