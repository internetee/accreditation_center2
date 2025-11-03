class TestAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :test
  has_many :question_responses, dependent: :destroy
  has_many :questions, through: :question_responses
  has_many :practical_task_results, dependent: :destroy
  has_many :practical_tasks, through: :practical_task_results

  validates :access_code, presence: true, uniqueness: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :not_completed, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil).where.not(started_at: nil) }
  scope :in_progress, -> { where.not(started_at: nil).where(completed_at: nil) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  def self.ransackable_attributes(auth_object = nil)
    %w[access_code completed_at created_at id passed score_percentage started_at test_id updated_at user_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[test user]
  end

  def merge_vars!(hash)
    update!(vars: vars.merge(hash.stringify_keys))
  end

  def set_started_at
    self.started_at = Time.zone.now
  end

  def complete!
    self.completed_at = Time.zone.now
    self.score_percentage = score_percentage
    self.passed = score_passed?
    save!

    # Send completion email notification
    AccreditationMailer.test_completion(user, self).deliver_now

    # Sync accreditation to REPP if user is fully accredited
    sync_accreditation_if_complete
  end

  def score_percentage
    if test.practical?
      return 0 if practical_task_results.empty?

      correct_count = practical_task_results.count(&:correct?)

      (correct_count.to_f / practical_task_results.count * 100).round(0)
    else
      return 0 if question_responses.empty?

      correct_count = question_responses.count(&:correct?)

      (correct_count.to_f / question_responses.count * 100).round(0)
    end
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
    question_responses.answered.includes(:question).map(&:question)
  end

  def unanswered_questions
    questions - answered_questions
  end

  def marked_for_later
    question_responses.where(marked_for_later: true).includes(:question).map(&:question)
  end

  def completed_tasks
    practical_task_results.includes(:practical_task).map(&:practical_task)
  end

  def incompleted_tasks
    test.practical_tasks.active - completed_tasks
  end

  def progress_percentage
    if test.practical?
      return 0 if test.practical_tasks.active.count.zero?

      (completed_tasks.count.to_f / test.practical_tasks.active.count * 100).round(1)
    else
      return 0 if test.questions.active.count.zero?

      (answered_questions.count.to_f / test.questions.active.count * 100).round(1)
    end
  end

  # Returns true when every question in this attempt has a selected answer
  def all_questions_answered?
    question_responses.all?(&:answered?)
  end

  def all_tasks_completed?
    return false if practical_task_results.count != test.practical_tasks.active.count

    practical_task_results.all? do |result|
      result.status == 'passed'
    end
  end

  def score_passed?
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
      practical_task_results.delete_all
    end
  end

  # Purge details for all attempts older than 30 days
  def self.purge_old_details!
    where('completed_at IS NOT NULL AND completed_at < ?', 30.days.ago).find_each do |attempt|
      attempt.purge_details!
    end
  end

  private

  def sync_accreditation_if_complete
    return unless passed?

    passed_tests = user.passed_tests.includes(:test)
    # Check if user has both theoretical and practical tests passed
    theoretical_passed = passed_tests.where(test: { test_type: :theoretical }).exists?
    practical_passed = passed_tests.where(test: { test_type: :practical }).exists?

    # Only sync if both tests are passed and this was the last one
    return unless theoretical_passed && practical_passed

    # Check if this is the most recent passed test
    latest_passed = passed_tests.last

    # This is the most recent test completion, sync to registry
    AccreditationSyncJob.perform_later(user.id) if latest_passed == self
  end
end
