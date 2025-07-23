class Question < ApplicationRecord
  belongs_to :test_category
  has_many :answers, dependent: :destroy
  has_many :question_responses, dependent: :destroy
  
  validates :text_et, presence: true
  validates :text_en, presence: true
  validates :question_type, presence: true, inclusion: { in: %w[multiple_choice practical] }
  validates :display_order, presence: true, numericality: { greater_than: 0 }
  
  scope :ordered, -> { order(:display_order) }
  scope :active, -> { where(active: true) }

  enum :question_type, { multiple_choice: 0, practical: 1 }
  
  def text(locale = I18n.locale)
    locale == :et ? text_et : text_en
  end
  
  def help_text(locale = I18n.locale)
    locale == :et ? help_text_et : help_text_en
  end
  
  def multiple_choice?
    question_type == 'multiple_choice'
  end
  
  def practical?
    question_type == 'practical'
  end
  
  def correct_answers
    answers.where(correct: true)
  end
  
  def correct_answer_ids
    correct_answers.pluck(:id)
  end
  
  def correct_answer_count
    correct_answers.count
  end
  
  def randomize_answers
    answers.shuffle
  end
end 