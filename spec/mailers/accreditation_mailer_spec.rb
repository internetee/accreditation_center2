require 'rails_helper'

RSpec.describe AccreditationMailer, type: :mailer do
  describe '#accreditation_granted_or_reaccredited' do
    let(:registrar) do
      create(
        :registrar,
        name: 'Alpha Registrar',
        email: 'registrar@example.com',
        accreditation_expire_date: Time.zone.parse('2028-04-10 10:00:00')
      )
    end

    it 'sends first-accreditation confirmation to registrar email' do
      mail = described_class.accreditation_granted_or_reaccredited(registrar, reaccreditation: false)

      expect(mail.to).to eq([registrar.email])
      expect(mail.subject).to eq(I18n.t('mailers.accreditation.accreditation_granted.subject', registrar: registrar.name))
      expect(mail.body.encoded).to include(registrar.name)
    end

    it 'uses reaccreditation subject when reaccreditation is true' do
      mail = described_class.accreditation_granted_or_reaccredited(registrar, reaccreditation: true)

      expect(mail.subject).to eq(I18n.t('mailers.accreditation.reaccreditation_granted.subject', registrar: registrar.name))
    end
  end

  describe '#expiry_30_days' do
    let(:registrar) do
      create(
        :registrar,
        name: 'Beta Registrar',
        email: 'beta@example.com',
        accreditation_expire_date: Date.new(2026, 5, 27)
      )
    end

    it 'sends reminder to registrar with localized expiry date in subject' do
      mail = described_class.expiry_30_days(registrar)
      expected_subject = I18n.t(
        'mailers.accreditation.expiry_30_days.subject',
        registrar: registrar.name,
        expiry_date: I18n.l(registrar.accreditation_expire_date.to_date, format: :default)
      )

      expect(mail.to).to eq([registrar.email])
      expect(mail.subject).to eq(expected_subject)
      expect(mail.body.encoded).to include(registrar.name)
    end
  end

  describe '#expiry_or_passed' do
    let(:registrar) do
      create(
        :registrar,
        name: 'Gamma Registrar',
        email: 'gamma@example.com',
        accreditation_expire_date: Date.new(2026, 4, 26)
      )
    end

    it 'sends expiry/passed notification to registrar' do
      mail = described_class.expiry_or_passed(registrar)

      expect(mail.to).to eq([registrar.email])
      expect(mail.subject).to eq(I18n.t('mailers.accreditation.expiry_or_passed.subject', registrar: registrar.name))
      expect(mail.body.encoded).to include(registrar.name)
    end
  end

  describe '#practical_passed_not_accredited' do
    let(:user) { create(:user, registrar_name: 'Delta Registrar', registrar_email: 'delta@example.com') }
    let(:registrar) { user.registrar }
    let(:test_attempt) { create(:test_attempt, :passed, user: user, test: create(:test, :practical, passing_score_percentage: 100)) }

    it 'sends practical-pass notice to registrar' do
      mail = described_class.practical_passed_not_accredited(registrar, test_attempt)

      expect(mail.to).to eq([registrar.email])
      expect(mail.subject).to eq(I18n.t('mailers.accreditation.practical_passed_not_accredited.subject', registrar: registrar.name))
      expect(mail.body.encoded).to include(registrar.name)
    end
  end

  describe '#theoretical_passed_not_accredited' do
    let(:user) { create(:user, registrar_name: 'Epsilon Registrar', registrar_email: 'epsilon@example.com') }
    let(:registrar) { user.registrar }
    let(:theoretical_test) { create(:test, :theoretical) }
    let(:test_category) { create(:test_category) }
    let!(:test_categories_test) { create(:test_categories_test, test: theoretical_test, test_category: test_category) }
    let!(:question) { create(:question, test_category: test_category) }
    let!(:answer) { create(:answer, question: question, correct: true) }
    let(:test_attempt) { create(:test_attempt, :passed, user: user, test: theoretical_test) }

    it 'sends theoretical-pass notice to registrar' do
      mail = described_class.theoretical_passed_not_accredited(registrar, test_attempt)

      expect(mail.to).to eq([registrar.email])
      expect(mail.subject).to eq(I18n.t('mailers.accreditation.theoretical_passed_not_accredited.subject', registrar: registrar.name))
      expect(mail.body.encoded).to include(registrar.name)
    end
  end

  describe '#admin_accreditation_window_notice' do
    let!(:admin1) { create(:user, :admin, email: 'admin1@example.com') }
    let!(:admin2) { create(:user, :admin, email: 'admin2@example.com') }
    let(:registrar) do
      create(
        :registrar,
        name: 'Zeta Registrar',
        accreditation_date: Date.new(2026, 4, 10),
        accreditation_expire_date: Date.new(2028, 4, 10)
      )
    end

    it 'sends admin window notice only to admins' do
      mail = described_class.admin_accreditation_window_notice(registrar)

      expect(mail.to).to match_array([admin1.email, admin2.email])
      expect(mail.subject).to eq(I18n.t('mailers.accreditation.admin_accreditation_window_notice.subject', registrar: registrar.name))
      expect(mail.body.encoded).to include(registrar.name)
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
