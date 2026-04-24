require 'rails_helper'

RSpec.describe Registrar, type: :model do
  describe 'validations' do
    it 'requires a name' do
      registrar = described_class.new(name: nil)

      expect(registrar.valid?).to be(false)
      expect(registrar.errors[:name]).to be_present
    end

    it 'enforces case-insensitive unique names' do
      create(:registrar, name: 'Registrar A')
      duplicate = build(:registrar, name: 'registrar a')

      expect(duplicate.valid?).to be(false)
      expect(duplicate.errors[:name]).to be_present
    end
  end

  describe 'associations' do
    it 'has users and test attempts through users' do
      registrar = create(:registrar)
      user = create(:user, registrar: registrar)
      test = create(:test, :theoretical)
      category = create(:test_category, name: 'Category 1')
      question = create(:question, test_category: category)
      create(:answer, question: question, correct: true)
      create(:test_categories_test, test: test, test_category: category)
      attempt = create(:test_attempt, user: user, test: test)

      expect(registrar.users).to include(user)
      expect(registrar.test_attempts).to include(attempt)
    end

    it 'restricts destroy when users exist' do
      registrar = create(:registrar)
      create(:user, registrar: registrar)

      expect { registrar.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end

  describe 'scopes' do
    it 'returns only registrars with non-admin users' do
      with_regular_user = create(:registrar, name: 'Regular Registrar')
      with_admin_only = create(:registrar, name: 'Admin Registrar')
      with_no_users = create(:registrar, name: 'Empty Registrar')

      create(:user, registrar: with_regular_user, role: :user)
      create(:user, :admin, registrar: with_admin_only)
      create(:user, registrar: with_regular_user, role: :user)

      result = described_class.with_non_admin_users

      expect(result).to include(with_regular_user)
      expect(result).not_to include(with_admin_only)
      expect(result).not_to include(with_no_users)
      expect(result.where(id: with_regular_user.id).count).to eq(1)
    end
  end

  describe 'accreditation helpers' do
    it 'detects expired accreditation' do
      registrar = create(:registrar, accreditation_expire_date: 1.day.ago)

      expect(registrar.accreditation_expired?).to be(true)
      expect(registrar.accreditation_expires_soon?).to be(true)
    end

    it 'detects accreditation expiring soon' do
      registrar = create(:registrar, accreditation_expire_date: 10.days.from_now)

      expect(registrar.accreditation_expired?).to be(false)
      expect(registrar.accreditation_expires_soon?).to be(true)
    end

    it 'returns nil days until expiry when no expiry date' do
      registrar = create(:registrar, accreditation_expire_date: nil)

      expect(registrar.days_until_accreditation_expiry).to be_nil
    end

    it 'returns non-negative days until expiry' do
      registrar = create(:registrar, accreditation_expire_date: 5.days.from_now)

      expect(registrar.days_until_accreditation_expiry).to be_between(4, 5)
    end
  end
end
