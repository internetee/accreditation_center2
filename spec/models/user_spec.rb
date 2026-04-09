require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'requires provider, uid and name' do
      user = build(:user, provider: nil, uid: nil, name: nil)

      expect(user.valid?).to be(false)
      expect(user.errors[:provider]).to be_present
      expect(user.errors[:uid]).to be_present
      expect(user.errors[:name]).to be_present
    end

    it 'requires password for admin users' do
      admin = build(:user, :admin, password: nil, password_confirmation: nil)

      expect(admin.valid?).to be(false)
      expect(admin.errors[:password]).to be_present
    end

    it 'requires password confirmation to match for admin users' do
      admin = build(:user, :admin, password: 'AdminPass123!', password_confirmation: 'DifferentPass123!')

      expect(admin.valid?).to be(false)
      expect(admin.errors[:password_confirmation]).to be_present
    end

    it 'allows duplicate registrar_name for users' do
      create(:user, role: :user, registrar_name: 'Registrar A')
      user = build(:user, role: :user, registrar_name: 'Registrar A')

      expect(user.valid?).to be(true)
    end

    it 'allows duplicate registrar_name for admins' do
      create(:user, :admin, registrar_name: 'Registrar A')
      admin = build(:user, :admin, registrar_name: 'Registrar A')

      expect(admin.valid?).to be(true)
    end
  end

  describe 'associations' do
    it 'has many test_attempts and tests through attempts' do
      user = create(:user)
      test = create(:test, :theoretical)
      test_category = create(:test_category)
      question = create(:question, test_category: test_category)
      create(:answer, question: question, correct: true)
      create(:test_categories_test, test: test, test_category: test_category)
      attempt = create(:test_attempt, user: user, test: test, passed: false)

      expect(user.test_attempts).to match_array([attempt])
      expect(user.tests).to match_array([test])
    end
  end

  describe 'defaults and scopes' do
    it 'sets default role to user on initialize' do
      user = described_class.new
      expect(user.role).to eq('user')
    end

    it 'returns not_admin scope' do
      u1 = create(:user, registrar_name: 'R')
      u2 = create(:user, :admin, role: :admin, password: 'AdminPass123!', password_confirmation: 'AdminPass123!')

      expect(described_class.not_admin).to include(u1)
      expect(described_class.not_admin).not_to include(u2)
    end
  end

  describe 'auth helpers' do
    it 'detects first_sign_in?' do
      user = create(:user)
      # Devise starts at 0, first successful sign-in would set to 1 in controller flows.
      # We assert the predicate logic relative to the stored counter value.
      user.update!(sign_in_count: 1)
      expect(user.first_sign_in?).to be(true)

      user.update!(sign_in_count: 2)
      expect(user.first_sign_in?).to be(false)
    end
  end

  describe 'accreditation-related helpers' do
    let!(:user) { create(:user) }
    let!(:test_category) { create(:test_category) }
    let!(:question) { create(:question, test_category: test_category) }
    let!(:answer) { create(:answer, question: question, correct: true) }
    let!(:test_categories_test) { create(:test_categories_test, test: theoretical, test_category: test_category) }
    let!(:theoretical) { create(:test, :theoretical, title: 'Theo') }
    let!(:practical)   { create(:test, :practical,   title: 'Prac') }

    it 'returns passed, failed, completed and in_progress collections' do
      a1 = create(:test_attempt, :passed, user: user, test: theoretical, started_at: 1.day.ago, completed_at: 23.hours.ago)
      a2 = create(:test_attempt, user: user, test: practical, passed: false, started_at: 2.hours.ago)

      expect(user.passed_tests).to match_array([a1])
      expect(user.failed_tests).to match_array([a2])
      expect(user.completed_tests).to include(a1)
      expect(user.in_progress_tests).to include(a2)
    end

    it 'detects accreditation_expired? and expires_soon?' do
      user.update!(registrar_accreditation_expire_date: 10.days.from_now)
      expect(user.registrar_accreditation_expired?).to be(false)
      expect(user.registrar_accreditation_expires_soon?).to be(true)

      user.update!(registrar_accreditation_expire_date: 1.day.ago)
      expect(user.registrar_accreditation_expired?).to be(true)
      expect(user.registrar_accreditation_expires_soon?).to be(true)
    end

    it 'returns days_until_accreditation_expiry' do
      user.update!(registrar_accreditation_expire_date: 5.days.from_now)
      expect(user.days_until_registrar_accreditation_expiry).to be_between(4, 5)

      user.update!(registrar_accreditation_expire_date: nil)
      expect(user.days_until_registrar_accreditation_expiry).to be_nil
    end

    it 'evaluates can_take_test? based on in-progress and recent passes' do
      # No attempts yet -> can take
      expect(user.can_take_test?(theoretical)).to be(true)

      # In-progress blocks
      create(:test_attempt, user: user, test: theoretical, passed: false, started_at: Time.current)
      expect(user.can_take_test?(theoretical)).to be(false)

      # Complete and passed recently (within 30 days) blocks
      create(:test_attempt, :passed, user: user, test: theoretical, started_at: Time.current, completed_at: Time.current)
      expect(user.can_take_test?(theoretical)).to be(false)
    end

    it 'returns test_history ordered desc by created_at' do
      a1 = create(:test_attempt, user: user, test: theoretical, passed: false, started_at: 2.days.ago, created_at: 2.days.ago)
      a2 = create(:test_attempt, user: user, test: theoretical, passed: false, started_at: 1.day.ago,  created_at: 1.day.ago)
      expect(user.test_history).to eq([a2, a1])
    end

    it 'computes test_statistics' do
      create(:test_attempt, :passed, user: user, test: theoretical, started_at: Time.current, completed_at: Time.current)
      create(:test_attempt, user: user, test: practical, passed: false, started_at: Time.current)

      stats = user.test_statistics
      expect(stats[:total]).to eq(2)
      expect(stats[:passed]).to eq(1)
      expect(stats[:failed]).to eq(1)
      expect(stats[:success_rate]).to eq(50.0)
    end
  end

  describe 'role helpers' do
    it 'returns admin? and user? predicates' do
      u = create(:user, registrar_name: 'R')
      expect(u.user?).to be(true)
      expect(u.admin?).to be(false)

      u.update!(role: :admin)
      expect(u.admin?).to be(true)
      expect(u.user?).to be(false)
    end
  end

  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: :oidc,
        uid: 'EE39901012239',
        info: OmniAuth::AuthHash::InfoHash.new(
          email: 'oidc@example.test',
          name: nil,
          given_name: 'Ok',
          family_name: 'Test'
        )
      )
    end

    it 'creates user from provider and uid' do
      user = described_class.from_omniauth(auth)

      expect(user).to be_persisted
      expect(user.provider).to eq('oidc')
      expect(user.uid).to eq('EE39901012239')
      expect(user.email).to eq('oidc@example.test')
      expect(user.name).to eq('Ok Test')
    end

    it 'returns existing user when provider and uid already exist' do
      existing = create(:user, provider: 'oidc', uid: 'EE39901012239', name: 'Existing User')

      user = described_class.from_omniauth(auth)

      expect(user.id).to eq(existing.id)
    end
  end
end
