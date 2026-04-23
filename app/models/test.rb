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

  validate :auto_assign_check
  def auto_assign_check
    return unless auto_assign?

    errors.add(:base, 'Auto assign allowed only for active tests') unless active?
    existing_auto_assign = Test.where(test_type: test_type, auto_assign: true).where.not(id: id)
    return unless existing_auto_assign.exists?

    errors.add(:base, 'Auto assign allowed only once for each test type')
  end

  scope :active, -> { where(active: true) }
  scope :auto_assignable, -> { where(auto_assign: true) }
  default_scope { order(created_at: :desc) }

  before_validation :set_practical_test_passing_score

  translates :title, :description

  def self.ransackable_associations(_auth_object = nil)
    %w[questions test_attempts test_categories]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title_et title_en description_et description_en created_at active auto_assign]
  end

  def active_ordered_test_categories_with_join_id
    sql = <<-SQL
      SELECT
        tc.*,
        tct.id as test_categories_test_id
      FROM test_categories tc
      INNER JOIN test_categories_tests tct ON tc.id = tct.test_category_id
      WHERE tct.test_id = #{id} AND tc.active = TRUE
      ORDER BY tct.display_order ASC
    SQL

    TestCategory.find_by_sql(sql)
  end

  def total_questions
    test_categories.sum(:questions_per_category)
  end

  def estimated_duration
    "#{time_limit_minutes} #{I18n.t('minutes')}"
  end

  def theoretical_questions_count
    questions.count if theoretical?
  end

  def practical_tasks_count
    practical_tasks.count if practical?
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

  def build_duplicate
    dup.tap do |new_test|
      copy_title_et, copy_title_en = next_unique_copy_titles

      new_test.title_et = copy_title_et
      new_test.title_en = copy_title_en
      new_test.description_et = "#{description_et} (Copy)" if description_et.present?
      new_test.description_en = "#{description_en} (Copy)" if description_en.present?
      new_test.active = false
      new_test.auto_assign = false
    end
  end

  private

  def next_unique_copy_titles
    suffix = 1

    loop do
      label = suffix == 1 ? 'Copy' : "Copy #{suffix}"
      candidate_et = "#{title_et} (#{label})"
      candidate_en = "#{title_en} (#{label})"

      et_taken = Test.exists?(title_et: candidate_et)
      en_taken = Test.exists?(title_en: candidate_en)
      return [candidate_et, candidate_en] unless et_taken || en_taken

      suffix += 1
    end
  end

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
      return random_slug unless Test.exists?(slug: random_slug)
    end
  end
end
