require 'rails_helper'

RSpec.describe Attempts::AutoAssign do
  describe '#call' do
    let(:user) { create(:user) }
    let!(:theoretical_test) { create_ready_theoretical_test }
    let!(:practical_test) { create(:test, :practical) }

    before do
      allow(Attempts::Assign).to receive(:call!).and_return(true)
    end

    it 'assigns missing theoretical and practical tests' do
      described_class.new(user: user).call

      expect(Attempts::Assign).to have_received(:call!).with(user: user, test: theoretical_test)
      expect(Attempts::Assign).to have_received(:call!).with(user: user, test: practical_test)
    end

    it 'does not assign when active attempts exist' do
      create(:test_attempt, user: user, test: theoretical_test, started_at: Time.current)
      create(:test_attempt, user: user, test: practical_test, started_at: Time.current)

      described_class.new(user: user).call

      expect(Attempts::Assign).not_to have_received(:call!)
    end

    it 'does not assign when both tests are not started' do
      create(:test_attempt, user: user, test: theoretical_test, started_at: nil)
      create(:test_attempt, user: user, test: practical_test, started_at: nil)

      described_class.new(user: user).call

      expect(Attempts::Assign).not_to have_received(:call!)
    end

    it 'does not assign when test is not started' do
      create(:test_attempt, user: user, test: theoretical_test, started_at: nil)
      create(:test_attempt, user: user, test: practical_test, started_at: Time.current)

      described_class.new(user: user).call

      expect(Attempts::Assign).not_to have_received(:call!)
    end

    it 'reassigns when existing attempt is expired' do
      create(:test_attempt, user: user, test: theoretical_test, started_at: 3.hours.ago, completed_at: nil)
      create(:test_attempt, user: user, test: practical_test, started_at: Time.current, completed_at: nil)

      described_class.new(user: user).call

      expect(Attempts::Assign).to have_received(:call!).with(user: user, test: theoretical_test)
      expect(Attempts::Assign).not_to have_received(:call!).with(user: user, test: practical_test)
    end

    it 'returns failures when assignment cannot proceed' do
      allow(Attempts::Assign).to receive(:call!).and_raise(StandardError, 'boom')

      failures = described_class.new(user: user).call

      expect(failures.size).to eq(2)
      expect(failures.first.test_type).to eq('theoretical')
      expect(failures.first.error_message).to eq('boom')
    end

    it 'returns a failure when no tests are available' do
      Test.destroy_all

      failures = described_class.new(user: user).call

      expect(failures.size).to eq(2)
      expect(failures.first.error_message).to include('No theoretical tests')
    end

    it 'returns a failure when test is inactive' do
      theoretical_test.update(active: false)

      failures = described_class.new(user: user).call

      expect(failures.size).to eq(1)
      expect(failures.first.error_message).to include('No theoretical tests available')
    end
  end

  def create_ready_theoretical_test
    test = create(:test, :theoretical)
    category = create(:test_category)
    create(:test_categories_test, test: test, test_category: category)
    question = create(:question, test_category: category)
    create(:answer, question: question, correct: true)
    test
  end
end
