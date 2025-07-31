class Answer < ApplicationRecord
  belongs_to :question

  validates :text_et, presence: true
  validates :text_en, presence: true

  def text(locale = I18n.locale)
    locale == :et ? text_et : text_en
  end

  def correct?
    correct == true
  end
end
