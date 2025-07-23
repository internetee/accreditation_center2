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

  translates :name
  
  def name(locale = I18n.locale)
    locale == :et ? name_et : name_en
  end
  
  def description(locale = I18n.locale)
    locale == :et ? description_et : description_en
  end
end
