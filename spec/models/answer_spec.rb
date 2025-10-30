require 'rails_helper'

RSpec.describe Answer, type: :model do
  let(:category) { create(:test_category) }
  let(:question) { create(:question, test_category: category) }

  describe 'associations' do
    it 'belongs to question' do
      answer = create(:answer, question: question)
      expect(answer.question).to eq(question)
      expect(question.answers).to include(answer)
    end
  end

  describe 'validations' do
    it 'validates presence of text_et and text_en' do
      answer = build(:answer, question: question, text_et: nil, text_en: nil)
      expect(answer.valid?).to be(false)
      expect(answer.errors[:text_et]).to be_present
      expect(answer.errors[:text_en]).to be_present

      answer = build(:answer, question: question, text_et: 'Vastus', text_en: 'Answer')
      expect(answer.valid?).to be(true)
    end
  end

  describe 'scopes' do
    it 'filters correct and incorrect answers' do
      a_correct = create(:answer, question: question, correct: true)
      a_incorrect = create(:answer, question: question, correct: false)

      expect(Answer.correct).to include(a_correct)
      expect(Answer.correct).not_to include(a_incorrect)
      expect(Answer.incorrect).to include(a_incorrect)
      expect(Answer.incorrect).not_to include(a_correct)
    end

    it 'orders by display_order asc' do
      a1 = create(:answer, question: question, display_order: 3)
      a2 = create(:answer, question: question, display_order: 1)
      a3 = create(:answer, question: question, display_order: 2)

      expect(Answer.ordered.map(&:id)).to eq([a2.id, a3.id, a1.id])
    end
  end

  describe 'instance methods' do
    it '#text returns et by default when locale :et' do
      I18n.with_locale(:et) do
        answer = create(:answer, question: question, text_et: 'Jah', text_en: 'Yes')
        expect(answer.text).to eq('Jah')
      end
    end

    it '#text returns en when locale :en' do
      I18n.with_locale(:en) do
        answer = create(:answer, question: question, text_et: 'Jah', text_en: 'Yes')
        expect(answer.text).to eq('Yes')
      end
    end

    it '#text respects explicit locale param' do
      answer = create(:answer, question: question, text_et: 'Jah', text_en: 'Yes')
      expect(answer.text(:et)).to eq('Jah')
      expect(answer.text(:en)).to eq('Yes')
    end

    it '#correct? returns true only when correct flag is true' do
      a1 = create(:answer, question: question, correct: true)
      a2 = create(:answer, question: question, correct: false)
      expect(a1.correct?).to be(true)
      expect(a2.correct?).to be(false)
    end
  end
end
