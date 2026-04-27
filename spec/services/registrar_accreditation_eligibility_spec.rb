require 'rails_helper'

RSpec.describe RegistrarAccreditationEligibility do
  let(:registrar) { create(:registrar, name: 'Registrar A') }
  let(:other_registrar) { create(:registrar, name: 'Registrar B') }

  let!(:theoretical_test) { create(:test, :theoretical) }
  let!(:practical_test) { create(:test, :practical) }
  let!(:test_category) { create(:test_category) }
  let!(:question) { create(:question, test_category: test_category) }
  let!(:answer) { create(:answer, :correct, question: question) }
  let!(:test_categories_test) { create(:test_categories_test, test: theoretical_test, test_category: test_category) }

  let(:registrar_user) { create(:user, registrar: registrar) }
  let(:teammate_user) { create(:user, registrar: registrar) }
  let(:other_registrar_user) { create(:user, registrar: other_registrar) }

  describe '.accredited?' do
    it 'returns false for missing registrar' do
      expect(described_class.accredited?(nil)).to be(false)
    end

    it 'returns false when only theoretical is passed' do
      create(:test_attempt, :passed, user: registrar_user, test: theoretical_test)

      expect(described_class.accredited?(registrar)).to be(false)
    end

    it 'returns false when only practical is passed' do
      create(:test_attempt, :passed, user: registrar_user, test: practical_test)

      expect(described_class.accredited?(registrar)).to be(false)
    end

    it 'returns true when registrar has both theoretical and practical passes' do
      create(:test_attempt, :passed, user: registrar_user, test: practical_test)
      create(:test_attempt, :passed, user: teammate_user, test: theoretical_test)

      expect(described_class.accredited?(registrar)).to be(true)
    end

    it 'does not use attempts from other registrars' do
      create(:test_attempt, :passed, user: registrar_user, test: practical_test)
      create(:test_attempt, :passed, user: other_registrar_user, test: theoretical_test)

      expect(described_class.accredited?(registrar)).to be(false)
    end
  end

  describe '#last_theory_passed_at' do
    it 'returns nil for missing registrar' do
      eligibility = described_class.new(nil)

      expect(eligibility.last_theory_passed_at).to be_nil
    end

    it 'returns latest completed_at for theoretical attempts of registrar' do
      older_theory = create(:test_attempt, :passed, user: registrar_user, test: theoretical_test, completed_at: 3.days.ago)
      newer_theory = create(:test_attempt, :passed, user: teammate_user, test: theoretical_test, completed_at: 1.day.ago)
      create(:test_attempt, :passed, user: registrar_user, test: practical_test, completed_at: Time.current)
      create(:test_attempt, :passed, user: other_registrar_user, test: theoretical_test, completed_at: Time.current)

      eligibility = described_class.new(registrar)

      expect(eligibility.last_theory_passed_at.to_i).to eq(newer_theory.completed_at.to_i)
      expect(eligibility.last_theory_passed_at.to_i).not_to eq(older_theory.completed_at.to_i)
    end
  end
end
