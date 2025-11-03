require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'validates presence and uniqueness of username and email' do
      u1 = create(:user) # use factory sequences to avoid collisions

      expect(u1).to be_persisted

      u2 = build(:user, username: u1.username, email: u1.email)

      expect(u2.valid?).to be(false)
      expect(u2.errors[:username]).to be_present
      expect(u2.errors[:email]).to be_present
    end

    it 'requires registrar_name when role is user' do
      user = build(:user, username: 'no-registrar', email: 'no-registrar@example.test', registrar_name: nil)

      # default role is user
      expect(user.role).to eq('user')
      expect(user.valid?).to be(false)
      expect(user.errors[:registrar_name]).to be_present

      user.registrar_name = 'Example Registrar'
      expect(user.valid?).to be(true)
    end
  end

  describe 'associations' do
    it 'has many test_attempts and tests through attempts' do
      user = create(:user)
      test = create(:test, :theoretical)
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
      u1 = create(:user, username: 'u1', email: 'u1@example.test', registrar_name: 'R')
      u2 = create(:user, username: 'u2', email: 'u2@example.test', registrar_name: 'R', role: :admin)

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

    it 'computes latest_accreditation only when both tests are passed' do
      # Only theoretical passed -> nil
      create(:test_attempt, :passed, user: user, test: theoretical, started_at: 3.hours.ago, completed_at: 2.hours.ago)
      expect(user.latest_accreditation).to be_nil

      # Add practical passed later -> latest should be practical attempt
      prac = create(:test_attempt, :passed, user: user, test: practical, started_at: 90.minutes.ago, completed_at: 30.minutes.ago)
      expect(user.latest_accreditation).to eq(prac)
    end

    it 'detects accreditation_expired? and expires_soon?' do
      user.update!(accreditation_expire_date: 10.days.from_now)
      expect(user.accreditation_expired?).to be(false)
      expect(user.accreditation_expires_soon?(30)).to be(true)

      user.update!(accreditation_expire_date: 1.day.ago)
      expect(user.accreditation_expired?).to be(true)
      expect(user.accreditation_expires_soon?(30)).to be(true)
    end

    it 'returns days_until_accreditation_expiry' do
      user.update!(accreditation_expire_date: 5.days.from_now)
      expect(user.days_until_accreditation_expiry).to be_between(4, 5)

      user.update!(accreditation_expire_date: nil)
      expect(user.days_until_accreditation_expiry).to be_nil
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
      u = create(:user, username: 'roles', email: 'roles@example.test', registrar_name: 'R')
      expect(u.user?).to be(true)
      expect(u.admin?).to be(false)

      u.update!(role: :admin)
      expect(u.admin?).to be(true)
      expect(u.user?).to be(false)
    end
  end
end
