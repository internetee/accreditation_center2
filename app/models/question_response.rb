class QuestionResponse < ApplicationRecord
  belongs_to :test_attempt
  belongs_to :question

  validates :selected_answer_ids, presence: true, unless: :marked_for_later?

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
    if marked_for_later?
      'marked_for_later'
    elsif correct?
      'correct'
    elsif answered?
      'incorrect'
    else
      'unanswered'
    end
  end

  def status_color
    case status
    when 'correct'
      'success'
    when 'incorrect'
      'danger'
    when 'marked_for_later'
      'warning'
    else
      'secondary'
    end
  end
end
