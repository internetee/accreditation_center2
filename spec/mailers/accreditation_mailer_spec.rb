require 'rails_helper'

RSpec.describe AccreditationMailer, type: :mailer do
  describe '#test_completion' do
    let(:user) { create(:user, email: 'user@example.com') }
    let(:test) { create(:test, :theoretical, title_en: 'Theoretical Test', title_et: 'Teoreetiline test') }
    let(:test_category) { create(:test_category) }
    let!(:test_categories_test) { create(:test_categories_test, test: test, test_category: test_category) }
    let!(:question) { create(:question, test_category: test_category) }
    let!(:answer) { create(:answer, question: question, correct: true) }
    let!(:question_response) { create(:question_response, test_attempt: test_attempt, question: question, selected_answer_ids: [answer.id]) }
    let!(:test_attempt) { create(:test_attempt, user: user, test: test, passed: true, completed_at: Time.current) }
    let(:mail) { described_class.test_completion(user, test_attempt) }

    it 'sends to the correct recipient' do
      expect(mail.to).to eq([user.email])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq("Test Completed - #{test.title}")
    end

    it 'includes user information in the body' do
      expect(mail.body.encoded).to include(user.name)
    end

    it 'includes test information' do
      expect(mail.body.encoded).to include(test.title)
    end

    context 'when test is passed' do
      it 'includes passed status' do
        expect(mail.body.encoded).to include('PASSED')
      end

      it 'includes score if present' do
        expect(mail.body.encoded).to include('100%')
      end
    end

    context 'when test is failed' do
      let(:test_attempt) { create(:test_attempt, user: user, test: test, passed: false, completed_at: Time.current) }

      it 'includes failed status' do
        expect(mail.body.encoded).to include('FAILED')
      end
    end
  end

  describe '#assignment_failed' do
    let(:user) { create(:user, email: 'registrar@example.com') }
    let!(:admin1) { create(:user, :admin, email: 'admin1@example.com') }
    let!(:admin2) { create(:user, :admin, email: 'admin2@example.com') }
    let(:failures) do
      [
        Attempts::AutoAssign::Failure.new(test_type: 'theoretical', error_message: 'No tests available'),
        Attempts::AutoAssign::Failure.new(test_type: 'practical', error_message: 'Provisioning failed')
      ]
    end
    let(:mail) { described_class.assignment_failed(user, failures) }

    it 'sends to all admin emails' do
      expect(mail.to).to match_array([admin1.email, admin2.email])
    end

    it 'uses the assignment failed subject' do
      expect(mail.subject).to eq("Automatic Test Assignment Failed for #{user.username}")
    end

    it 'lists each failure in the body' do
      expect(mail.body.encoded).to include('Theoretical')
      expect(mail.body.encoded).to include('No tests available')
      expect(mail.body.encoded).to include('Practical')
      expect(mail.body.encoded).to include('Provisioning failed')
    end
  end
end
