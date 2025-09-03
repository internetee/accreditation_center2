class TestCategory < ApplicationRecord
  has_many :test_categories_tests, dependent: :destroy
  has_many :tests, through: :test_categories_tests
  has_many :questions, -> { order(:display_order) }, dependent: :destroy

  validates :name_et, presence: true
  validates :name_en, presence: true
  # validates :domain_rule_reference, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :domain_rule_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  scope :active, -> { where(active: true) }

  translates :name, :description

  def self.ransackable_attributes(auth_object = nil)
    %w[active created_at description_en description_et domain_rule_reference domain_rule_url id id_value name_en name_et questions_per_category updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[questions tests]
  end
end
