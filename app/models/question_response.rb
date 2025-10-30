class QuestionResponse < ApplicationRecord
  belongs_to :test_attempt
  belongs_to :question

  validates :selected_answer_ids, presence: true, unless: :marked_for_later?, on: :update

  default_scope { order(created_at: :asc) }

  scope :answered, -> { where.not(marked_for_later: true).where.not(selected_answer_ids: []) }

  def selected_answers
    Answer.where(id: selected_answer_ids)
  end

  def correct?
    return false if marked_for_later?
    return false if selected_answer_ids.blank?

    correct_answer_ids = question.correct_answer_ids
    selected_answer_ids.sort == correct_answer_ids.sort
  end

  def partially_correct?
    return false if marked_for_later?
    return false if selected_answer_ids.blank?

    correct_selected = selected_answer_ids & question.correct_answer_ids
    incorrect_selected = selected_answer_ids - question.correct_answer_ids

    correct_selected.any? && incorrect_selected.empty?
  end

  def answered?
    selected_answer_ids.present?
  end

  def status
    if marked_for_later? && test_attempt.in_progress?
      'marked_for_later'
    elsif correct? && test_attempt.completed?
      'correct'
    elsif !correct? && test_attempt.completed?
      'incorrect'
    elsif answered?
      'correct'
    else
      'unanswered'
    end
  end
end
