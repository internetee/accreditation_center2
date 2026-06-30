class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :trackable, :omniauthable, omniauth_providers: [:oidc]

  # Associations
  belongs_to :registrar, optional: true
  has_many :test_attempts, dependent: :destroy
  has_many :tests, through: :test_attempts

  validates :provider, :uid, :name, presence: true, unless: :admin?
  validates :email, presence: true, uniqueness: { case_sensitive: false }, if: :admin?
  validates :username, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :password, presence: true, if: :admin_password_required?
  validates :password, confirmation: true, if: :admin_password_required?

  def admin_password_required?
    admin? && (new_record? || password.present?)
  end

  enum :role, { user: 0, admin: 1 }

  after_initialize :set_default_role, if: :new_record?

  scope :not_admin, -> { where.not(role: :admin) }
  scope :admin, -> { where(role: :admin) }

  def self.from_omniauth(auth, provider: 'oidc')
    uid = auth.uid.to_s
    info = auth_info(auth)
    find_or_initialize_by(provider: provider.to_s, uid: uid).tap do |user|
      user.role ||= 'user'
      user.email = info[:email] if info[:email].present?
      user.name = resolved_omniauth_name(user: user, info: info)
    end
  end

  def self.resolved_omniauth_name(user:, info:)
    user.name.presence || omniauth_full_name(info).presence || info[:name]
  end
  private_class_method :resolved_omniauth_name

  def self.omniauth_full_name(info)
    [info[:given_name], info[:family_name]].compact.join(' ').strip
  end
  private_class_method :omniauth_full_name

  def self.auth_info(auth)
    {
      email: auth.dig('info', 'email'),
      name: auth.dig('info', 'name'),
      given_name: auth.dig('info', 'given_name'),
      family_name: auth.dig('info', 'family_name')
    }
  end
  private_class_method :auth_info

  def self.ransackable_attributes(auth_object = nil)
    %w[name uid registrar_id registrar_name username role]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[registrar test_attempts tests]
  end

  delegate :name, to: :registrar, prefix: true, allow_nil: true
  delegate :email, :accreditation_date, :accreditation_expire_date, to: :registrar, prefix: true, allow_nil: true

  ransacker :registrar_name do
    Arel.sql('(SELECT registrars.name FROM registrars WHERE registrars.id = users.registrar_id)')
  end

  def assign_registrar_from_api!(registrar_name:, registrar_email:, accreditation_date:, accreditation_expire_date:)
    normalized_name = registrar_name.to_s.strip
    return if normalized_name.blank?

    self.registrar = Registrar.find_or_initialize_by(name: normalized_name)
    registrar.email = registrar_email if registrar_email.present?
    registrar.accreditation_date = accreditation_date
    registrar.accreditation_expire_date = accreditation_expire_date
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

  def display_name
    name.presence || username
  end

  def admin?
    role == 'admin'
  end

  def user?
    role == 'user'
  end
end
