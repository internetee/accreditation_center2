class Test < ApplicationRecord
  has_and_belongs_to_many :test_categories
  has_many :test_attempts, dependent: :destroy
  has_many :questions, through: :test_categories

  validates :title_et, presence: true
  validates :title_en, presence: true
  # validates :description_et, presence: true
  # validates :description_en, presence: true
  validates :time_limit_minutes, presence: true, numericality: { greater_than: 0 }
  validates :questions_per_category, presence: true, numericality: { greater_than: 0 }
  validates :passing_score_percentage, presence: true, numericality: { in: 0..100 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(display_order: :asc) }
  default_scope { order(created_at: :desc) }

  translates :title, :description

  def self.ransackable_associations(auth_object = nil)
    ['questions', 'test_attempts', 'test_categories']
  end

  def self.ransackable_attributes(auth_object = nil)
    ['title_et', 'title_en', 'description_et', 'description_en', 'created_at']
  end

  def total_questions
    test_categories.sum(:questions_per_category)
  end

  def estimated_duration
    "#{time_limit_minutes} #{I18n.t('minutes')}"
  end
end
