require 'rails_helper'

RSpec.describe AccreditationMailer, type: :mailer do
  describe '#expiry_warning' do
    let(:user) { create(:user, email: 'user@example.com', accreditation_expire_date: 30.days.from_now) }
    let(:days_before) { 30 }
    let(:mail) { described_class.expiry_warning(user, days_before) }

    it 'sends to the correct recipient' do
      expect(mail.to).to eq([user.email])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq("Accreditation Expires in #{days_before} Days")
    end

    it 'includes user information in the body' do
      expect(mail.body.encoded).to include(user.username)
    end

    it 'includes expiry date information' do
      expect(mail.body.encoded).to include(user.accreditation_expire_date.strftime('%B %d, %Y'))
    end

    it 'includes days before expiry' do
      expect(mail.body.encoded).to include(days_before.to_s)
    end

    it 'includes renewal link' do
      expect(mail.body.encoded).to include(root_url)
    end
  end

  describe '#expiry_notification' do
    let(:user) { create(:user, email: 'user@example.com', accreditation_expire_date: Time.zone.today) }
    let(:mail) { described_class.expiry_notification(user) }

    it 'sends to the correct recipient' do
      expect(mail.to).to eq([user.email])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq('Accreditation Expired - Action Required')
    end

    it 'includes user information in the body' do
      expect(mail.body.encoded).to include(user.username)
    end

    it 'includes expiry date in the body' do
      expect(mail.body.encoded).to include(user.accreditation_expire_date.strftime('%B %d, %Y'))
    end

    it 'includes renewal link' do
      expect(mail.body.encoded).to include(root_url)
    end

    it 'sets instance variables correctly' do
      expect(mail.body.encoded).to include('Accreditation Expired')
    end
  end

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
      expect(mail.body.encoded).to include(user.username)
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

  describe '#coordinator_notification' do
    let(:user1) { create(:user, email: 'user1@example.com', accreditation_expire_date: 5.days.from_now) }
    let(:user2) { create(:user, email: 'user2@example.com', accreditation_expire_date: 10.days.from_now) }
    let(:expiring_users) { [user1, user2] }
    let(:mail) { described_class.coordinator_notification(expiring_users) }

    before do
      allow(ENV).to receive(:fetch).with('COORDINATOR_EMAIL', 'info@internet.ee').and_return('coordinator@example.com')
    end

    it 'sends to the coordinator email' do
      expect(mail.to).to eq(['coordinator@example.com'])
    end

    it 'has the correct subject with count' do
      expect(mail.subject).to eq("Accreditation Expiry Alert - #{expiring_users.count} Users")
    end

    it 'includes user information in the body' do
      expect(mail.body.encoded).to include(user1.username)
      expect(mail.body.encoded).to include(user2.username)
    end

    it 'includes user emails in the body' do
      expect(mail.body.encoded).to include(user1.email)
      expect(mail.body.encoded).to include(user2.email)
    end

    it 'includes expiry dates in the body' do
      expect(mail.body.encoded).to include(user1.accreditation_expire_date.strftime('%B %d, %Y'))
      expect(mail.body.encoded).to include(user2.accreditation_expire_date.strftime('%B %d, %Y'))
    end

    context 'when COORDINATOR_EMAIL is set' do
      before do
        allow(ENV).to receive(:fetch).with('COORDINATOR_EMAIL', 'info@internet.ee').and_return('custom@example.com')
      end

      it 'uses the custom coordinator email' do
        mail = described_class.coordinator_notification(expiring_users)
        expect(mail.to).to eq(['custom@example.com'])
      end
    end

    context 'when COORDINATOR_EMAIL is not set' do
      before do
        allow(ENV).to receive(:fetch).with('COORDINATOR_EMAIL', 'info@internet.ee').and_return('info@internet.ee')
      end

      it 'uses the default coordinator email' do
        mail = described_class.coordinator_notification(expiring_users)
        expect(mail.to).to eq(['info@internet.ee'])
      end
    end
  end
end
