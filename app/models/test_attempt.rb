class TestAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :test
  has_many :question_responses, dependent: :destroy
  has_many :questions, through: :question_responses

  validates :access_code, presence: true, uniqueness: true

  before_validation :generate_access_code, on: :create

  scope :ordered, -> { order(created_at: :desc) }
  scope :not_completed, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil).where.not(started_at: nil) }
  scope :in_progress, -> { where(completed_at: nil) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  def self.ransackable_attributes(auth_object = nil)
    %w[access_code completed_at created_at id passed score_percentage started_at test_id updated_at user_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[test user]
  end

  def generate_access_code
    return if access_code.present?

    self.access_code = SecureRandom.hex(8)
  end

  def set_started_at
    self.started_at = Time.zone.now
  end

  def complete!
    self.completed_at = Time.zone.now
    save!
  end

  def completed?
    completed_at.present?
  end

  def not_started?
    !completed? && started_at.blank?
  end

  def in_progress?
    !completed? && !started_at.blank?
  end

  def failed?
    !passed? && completed?
  end

  def time_remaining
    return 0 if completed?
    return test.time_limit_minutes * 60 if started_at.blank?

    elapsed = Time.zone.now - started_at
    remaining = (test.time_limit_minutes * 60) - elapsed.to_i
    [remaining, 0].max
  end

  def time_elapsed
    return 0 if started_at.blank?

    elapsed = completed_at ? completed_at - started_at : Time.zone.now - started_at

    [elapsed, test.time_limit_minutes * 60].min
  end

  def time_warning?
    time_remaining <= 5.minutes && time_remaining.positive?
  end

  def time_expired?
    time_remaining <= 0
  end

  def answered_questions
    question_responses.includes(:question).map(&:question)
  end

  def unanswered_questions
    questions - answered_questions
  end

  def marked_for_later
    question_responses.where(marked_for_later: true).includes(:question).map(&:question)
  end

  def progress_percentage
    return 100 if test.questions.active.count.zero?

    (answered_questions.count.to_f / test.questions.active.count * 100).round(1)
  end

  # Returns true when every question in this attempt has a selected answer
  def all_questions_answered?
    question_responses.where(selected_answer_ids: []).none?
  end

  def score_percentage
    return 0 if question_responses.empty?

    correct_count = question_responses.count(&:correct?)

    (correct_count.to_f / question_responses.count * 100).round(0)
  end

  def passed?
    score_percentage >= test.passing_score_percentage
  end

  def can_continue?
    in_progress? && !time_expired?
  end

  # Initializes a per-attempt randomized question set based on test categories.
  # Selects up to questions_per_category active questions from each active category
  # and creates placeholder QuestionResponse records to persist the selection.
  def initialize_question_set!
    return if question_responses.exists?

    test.test_categories.active.find_each do |category|
      # Fallback to 5 if questions_per_category is not present
      per_category_limit = category.respond_to?(:questions_per_category) && category.questions_per_category.present? ? category.questions_per_category.to_i : 5

      available_ids = category.questions.active.pluck(:id)
      next if available_ids.empty?

      selected_ids = available_ids.sample([per_category_limit, available_ids.size].min)
      selected_ids.each do |question_id|
        question_responses.create!(question_id: question_id, selected_answer_ids: [], marked_for_later: false)
      end
    end
  end

  # Returns true if detailed results should no longer be shown (older than 30 days)
  def details_expired?
    completed? && completed_at < 30.days.ago
  end

  # Remove detailed responses while keeping the overall result
  def purge_details!
    transaction do
      question_responses.delete_all
      update!(score_percentage: nil)
    end
  end

  # Purge details for all attempts older than 30 days
  def self.purge_old_details!
    where('completed_at IS NOT NULL AND completed_at < ?', 30.days.ago).find_each do |attempt|
      attempt.purge_details!
    end
  end
end
