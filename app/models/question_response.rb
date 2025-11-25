class QuestionResponse < ApplicationRecord
  belongs_to :test_attempt
  belongs_to :question

  validate :selected_answer_or_marked_for_later, on: :update

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
    return 'marked_for_later' if marked_for_later_in_progress?
    return 'correct' if completed_and_correct?
    return 'incorrect' if completed_and_incorrect?
    return 'correct' if answered?

    'unanswered'
  end

  private

  def marked_for_later_in_progress?
    marked_for_later? && test_attempt.in_progress?
  end

  def completed_and_correct?
    correct? && test_attempt.completed?
  end

  def completed_and_incorrect?
    !correct? && test_attempt.completed?
  end

  def selected_answer_or_marked_for_later
    if !marked_for_later? && (selected_answer_ids.blank? || selected_answer_ids.empty?)
      errors.add(:base, I18n.t('tests.select_answer_or_marked_for_later'))
    end
  end
end
