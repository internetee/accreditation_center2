class Registrar < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :test_attempts, through: :users

  scope :with_non_admin_users, -> { joins(:users).merge(User.not_admin).distinct }

  def self.ransackable_attributes(_auth_object = nil)
    %w[accreditation_date accreditation_expire_date created_at email id name updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[test_attempts users]
  end

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def accreditation_expired?
    accreditation_expire_date.present? && accreditation_expire_date < Time.current
  end

  def accreditation_expires_soon?
    accreditation_expire_date.present? && accreditation_expire_date - 30.days < Time.current
  end

  def days_until_accreditation_expiry
    return nil unless accreditation_expire_date.present?

    (accreditation_expire_date.to_date - Time.zone.today).to_i.clamp(0, Float::INFINITY)
  end
end
