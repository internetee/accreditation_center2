class TestCategory < ApplicationRecord
  has_and_belongs_to_many :tests
  has_many :questions, dependent: :destroy

  validates :name_et, presence: true
  validates :name_en, presence: true
  validates :domain_rule_reference, presence: true
  validates :questions_per_category, presence: true, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [true, false] }
  scope :ordered, -> { order(:display_order) }
  scope :active, -> { where(active: true) }

  translates :name, :description

  def self.ransackable_attributes(auth_object = nil)
    %w[active created_at description_en description_et display_order domain_rule_reference id id_value name_en name_et questions_per_category updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[questions tests]
  end
end
