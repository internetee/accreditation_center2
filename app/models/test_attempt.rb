class TestAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :test
  has_many :question_responses, dependent: :destroy
  has_many :questions, through: :question_responses

  validates :started_at, presence: true
  validates :access_code, presence: true, uniqueness: true

  before_create :generate_access_code
  before_create :set_started_at

  scope :ordered, -> { order(created_at: :desc) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :in_progress, -> { where(completed_at: nil) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  def generate_access_code
    self.access_code = SecureRandom.hex(8)
  end

  def set_started_at
    self.started_at = Time.current
  end

  def complete!
    self.completed_at = Time.current
    save!
  end

  def completed?
    completed_at.present?
  end

  def in_progress?
    !completed?
  end

  def time_remaining
    return 0 if completed?

    elapsed = Time.current - started_at
    remaining = (test.time_limit_minutes * 60) - elapsed.to_i
    [remaining, 0].max
  end

  def time_elapsed
    return completed_at - started_at if completed?

    Time.current - started_at
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
    test.questions.active - answered_questions
  end

  def marked_for_later
    question_responses.where(marked_for_later: true).includes(:question).map(&:question)
  end

  def progress_percentage
    return 100 if test.questions.active.count.zero?

    (answered_questions.count.to_f / test.questions.active.count * 100).round(1)
  end

  def score_percentage
    return 0 if question_responses.empty?

    correct_responses = question_responses.joins(:question).where(
      'question_responses.selected_answer_ids @> ARRAY[?]::integer[]', 
      Question.joins(:answers).where(answers: { correct: true }).pluck('answers.id')
    ).count

    (correct_responses.to_f / question_responses.count * 100).round(1)
  end

  def passed?
    score_percentage >= test.passing_score_percentage
  end

  def can_continue?
    in_progress? && !time_expired?
  end
end
