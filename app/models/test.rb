class Test < ApplicationRecord
  extend FriendlyId
  friendly_id :generate_random_slug, use: :slugged

  enum :test_type, { theoretical: 0, practical: 1 }

  has_many :test_categories_tests, dependent: :destroy
  has_many :test_categories, through: :test_categories_tests
  has_many :test_attempts, dependent: :destroy
  has_many :questions, through: :test_categories
  has_many :practical_tasks, dependent: :destroy

  validates :title_et, presence: true
  validates :title_en, presence: true
  validates :test_type, presence: true
  # validates :description_et, presence: true
  # validates :description_en, presence: true
  validates :time_limit_minutes, presence: true, numericality: { greater_than: 0 }
  validates :passing_score_percentage, presence: true, numericality: { in: 0..100 }
  validate :practical_test_passing_score

  scope :active, -> { where(active: true) }
  default_scope { order(created_at: :desc) }

  before_validation :set_practical_test_passing_score

  def active_ordered_test_categories_with_join_id
    sql = <<-SQL
      SELECT
        tc.*,
        tct.id as test_categories_test_id
      FROM test_categories tc
      INNER JOIN test_categories_tests tct ON tc.id = tct.test_category_id
      WHERE tct.test_id = #{id}
      ORDER BY tct.display_order ASC
    SQL

    TestCategory.active.find_by_sql(sql)
  end

  translates :title, :description

  def self.ransackable_associations(_auth_object = nil)
    %w[questions test_attempts test_categories]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title_et title_en description_et description_en created_at]
  end

  def total_questions
    test_categories.sum(:questions_per_category)
  end

  def estimated_duration
    "#{time_limit_minutes} #{I18n.t('minutes')}"
  end

  def has_theoretical_questions?
    theoretical?
  end

  def has_practical_tasks?
    practical?
  end

  def theoretical_questions_count
    questions.count if has_theoretical_questions?
  end

  def practical_tasks_count
    practical_tasks.count if has_practical_tasks?
  end

  def total_components
    if theoretical?
      theoretical_questions_count
    elsif practical?
      practical_tasks_count
    else
      0
    end
  end

  private

  def practical_test_passing_score
    return unless practical? && passing_score_percentage != 100

    errors.add(:passing_score_percentage, 'must be 100% for practical tests')
  end

  def set_practical_test_passing_score
    return unless practical?

    self.passing_score_percentage = 100
  end

  def generate_random_slug
    loop do
      # Generate a random 8-character alphanumeric string
      random_slug = SecureRandom.alphanumeric(8).downcase
      # Check if this slug already exists
      unless Test.exists?(slug: random_slug)
        return random_slug
      end
    end
  end
end
