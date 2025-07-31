class Test < ApplicationRecord
  has_many :test_categories_tests, dependent: :destroy
  has_many :test_categories, through: :test_categories_tests
  has_many :test_attempts, dependent: :destroy
  has_many :questions, through: :test_categories

  validates :title_et, presence: true
  validates :title_en, presence: true
  # validates :description_et, presence: true
  # validates :description_en, presence: true
  validates :time_limit_minutes, presence: true, numericality: { greater_than: 0 }
  validates :passing_score_percentage, presence: true, numericality: { in: 0..100 }

  scope :active, -> { where(active: true) }
  default_scope { order(created_at: :desc) }

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

  def self.ransackable_associations(auth_object = nil)
    %w[questions test_attempts test_categories]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title_et title_en description_et description_en created_at]
  end

  def total_questions
    test_categories.sum(:questions_per_category)
  end

  def estimated_duration
    "#{time_limit_minutes} #{I18n.t('minutes')}"
  end
end
