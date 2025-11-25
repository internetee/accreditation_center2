# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attempts::Assign do
  describe '.call!' do
    let(:user) { create(:user) }

    context 'when the test is theoretical' do
      let(:test) { create_theoretical_test }

      before do
        allow(SecureRandom).to receive(:hex).with(8).and_return('fixedcode')
      end

      it 'creates and returns a new test attempt without provisioning tasks' do
        expect(Attempts::Provisioner).not_to receive(:provision!)

        attempt = nil
        expect do
          attempt = described_class.call!(user: user, test: test)
        end.to change(TestAttempt, :count).by(1)

        expect(attempt).to be_persisted
        expect(attempt.user).to eq(user)
        expect(attempt.test).to eq(test)
        expect(attempt.access_code).to eq('fixedcode')
        expect(attempt.started_at).to be_nil
      end
    end

    context 'when the test is practical' do
      let(:test) { create(:test, :practical) }

      it 'provisions tasks after creating the attempt' do
        allow(SecureRandom).to receive(:hex).with(8).and_return('practicalcode')
        expect(Attempts::Provisioner).to receive(:provision!) do |attempt|
          expect(attempt).to be_a(TestAttempt)
          expect(attempt.test).to eq(test)
        end

        attempt = described_class.call!(user: user, test: test)
        expect(attempt.access_code).to eq('practicalcode')
      end
    end

    context 'when provisioning raises an error' do
      let(:test) { create(:test, :practical) }

      it 'rolls back the transaction and re-raises the error' do
        allow(Attempts::Provisioner).to receive(:provision!).and_raise(StandardError, 'boom')

        expect do
          expect do
            described_class.call!(user: user, test: test)
          end.to raise_error(StandardError, 'boom')
        end.not_to change(TestAttempt, :count)
      end
    end
  end

  def create_theoretical_test
    test = create(:test, :theoretical)
    test_category = create(:test_category)
    create(:test_categories_test, test: test, test_category: test_category)
    question = create(:question, test_category: test_category)
    create(:answer, :correct, question: question)
    test
  end
end
