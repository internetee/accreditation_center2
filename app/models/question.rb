class Question < ApplicationRecord
  belongs_to :test_category
  positioned on: :test_category, column: :display_order
  has_many :answers, dependent: :destroy
  has_many :question_responses, dependent: :destroy

  validates :text_et, presence: true
  validates :text_en, presence: true
  validates :question_type, presence: true, inclusion: { in: %w[multiple_choice] }
  validates :display_order, presence: true, numericality: { greater_than: 0 }
  validate :mandatory_only_if_active
  def mandatory_only_if_active
    return unless mandatory? && !active?

    errors.add(:base, 'Mandatory question must be active')
  end

  scope :ordered, -> { order(:display_order) }
  scope :active, -> { where(active: true) }
  scope :mandatory, -> { where('mandatory_to IS NOT NULL AND mandatory_to >= ?', Time.zone.now) }
  scope :non_mandatory, -> { where('mandatory_to IS NULL OR mandatory_to < ?', Time.zone.now) }

  enum :question_type, { multiple_choice: 'multiple_choice' }

  translates :text, :help_text

  attr_accessor :mandatory

  before_validation :update_mandatory_to
  def update_mandatory_to
    if mandatory == '1'
      validity = ENV.fetch('MANDATORY_QUESTION_VALIDITY_YEARS', 1).to_i
      self.mandatory_to = Date.current + validity.years unless mandatory?
    else
      self.mandatory_to = nil
    end
  end

  def multiple_choice?
    question_type == 'multiple_choice'
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

  # Returns true if this question is currently mandatory
  # (mandatory_to is set and the date hasn't passed yet)
  def mandatory?
    return false if mandatory_to.blank?

    mandatory_to >= Date.current
  end
end
