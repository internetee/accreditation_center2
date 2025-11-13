class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Associations
  has_many :test_attempts, dependent: :destroy
  has_many :tests, through: :test_attempts

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :registrar_name, length: { maximum: 255 }, presence: true, if: -> { role == 'user' }

  enum :role, { user: 0, admin: 1 }

  after_initialize :set_default_role, if: :new_record?

  scope :not_admin, -> { where.not(role: :admin) }

  def self.ransackable_attributes(auth_object = nil)
    %w[username email registrar_name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[test_attempts tests]
  end

  def set_default_role
    self.role ||= 'user'
  end

  def first_sign_in?
    sign_in_count == 1
  end

  def last_sign_in_ip_address
    last_sign_in_ip
  end

  def current_sign_in_ip_address
    current_sign_in_ip
  end

  # Accreditation methods
  def passed_tests
    test_attempts.where(passed: true)
  end

  def failed_tests
    test_attempts.where(passed: false)
  end

  def completed_tests
    test_attempts.completed
  end

  def in_progress_tests
    test_attempts.in_progress
  end

  def latest_accreditation
    # Get the last passed theoretical and practical tests
    passed_test_attempts = passed_tests.includes(:test).order(:created_at)
    last_theoretical = passed_test_attempts.where(test: { test_type: :theoretical }).last
    last_practical = passed_test_attempts.where(test: { test_type: :practical }).last

    # Only return accreditation if both tests are passed
    return nil if last_theoretical.nil? || last_practical.nil?

    # Return the later of the two (last one completed)
    last_theoretical.created_at > last_practical.created_at ? last_theoretical : last_practical
  end

  def accreditation_expired?
    return true if accreditation_expire_date.nil?

    accreditation_expire_date < Time.current
  end

  def accreditation_expires_soon?(days = 30)
    return false if accreditation_expire_date.nil?

    accreditation_expire_date < days.days.from_now
  end

  def days_until_accreditation_expiry
    return nil if accreditation_expire_date.nil?

    (accreditation_expire_date - Time.current).to_i / 1.day
  end

  def can_take_test?(test)
    # Check if user has an in-progress attempt for this test
    in_progress_attempt = test_attempts.in_progress.find_by(test: test)
    return false if in_progress_attempt.present?

    # Check if user has passed this test recently (within 30 days)
    recent_passed = passed_tests.where(test: test).where('created_at > ?', 30.days.ago)
    return false if recent_passed.exists?

    true
  end

  def test_history
    test_attempts.includes(:test).order(created_at: :desc)
  end

  def test_statistics
    total_attempts = test_attempts.count
    passed_attempts = passed_tests.count
    failed_attempts = failed_tests.count

    {
      total: total_attempts,
      passed: passed_attempts,
      failed: failed_attempts,
      success_rate: total_attempts.positive? ? (passed_attempts.to_f / total_attempts * 100).round(1) : 0
    }
  end

  def admin?
    role == 'admin'
  end

  def user?
    role == 'user'
  end
end
