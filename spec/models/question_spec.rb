require 'rails_helper'

RSpec.describe Question, type: :model do
  let(:test_category) { create(:test_category) }

  describe 'validations' do
    it 'validates presence of text_et and text_en' do
      question = build(:question, text_et: nil, text_en: nil, test_category: test_category)
      expect(question.valid?).to be(false)
      expect(question.errors[:text_et]).to be_present
      expect(question.errors[:text_en]).to be_present

      question = build(:question, text_et: 'Küsimus', text_en: 'Question', test_category: test_category)
      expect(question.valid?).to be(true)
    end

    it 'validates presence of question_type' do
      question = build(:question, question_type: nil, test_category: test_category)
      expect(question.valid?).to be(false)
      expect(question.errors[:question_type]).to be_present

      question = build(:question, question_type: 'multiple_choice', test_category: test_category)
      expect(question.valid?).to be(true)
    end

    it 'validates presence of display_order' do
      question = build(:question, display_order: nil, test_category: test_category)
      expect(question.valid?).to be(false)
      expect(question.errors[:display_order]).to be_present

      question = build(:question, display_order: 1, test_category: test_category)
      expect(question.valid?).to be(true)
    end

    it 'validates display_order is greater than 0' do
      question = build(:question, display_order: 0, test_category: test_category)
      expect(question.valid?).to be(false)
      expect(question.errors[:display_order]).to be_present

      question = build(:question, display_order: -1, test_category: test_category)
      expect(question.valid?).to be(false)
      expect(question.errors[:display_order]).to be_present

      question = build(:question, display_order: 1, test_category: test_category)
      expect(question.valid?).to be(true)
    end

    it 'validates mandatory only if active' do
      question = build(:question, mandatory: '1', active: false, test_category: test_category)
      expect(question.valid?).to be(false)
      expect(question.errors[:base]).to include('Mandatory question must be active')

      question = build(:question, mandatory: '1', active: true, test_category: test_category)
      expect(question.valid?).to be(true)
    end
  end

  describe 'associations' do
    let(:test) { create(:test, :theoretical) }
    let(:question) { create(:question, test_category: test_category) }

    it 'belongs to test_category' do
      expect(question.test_category).to eq(test_category)
      expect(test_category.questions).to include(question)
    end

    it 'has many answers' do
      answer1 = create(:answer, question: question)
      answer2 = create(:answer, question: question)

      expect(question.answers).to include(answer1, answer2)
    end

    it 'destroys associated answers when destroyed' do
      answer = create(:answer, question: question)

      question.destroy

      expect(Answer.find_by(id: answer.id)).to be_nil
    end

    it 'has many question_responses' do
      create(:answer, question: question, correct: true)
      create(:test_categories_test, test: test, test_category: test_category)
      test_attempt1 = create(:test_attempt, test: test)
      test_attempt2 = create(:test_attempt, test: test)
      response1 = create(:question_response, question: question, test_attempt: test_attempt1)
      response2 = create(:question_response, question: question, test_attempt: test_attempt2)

      expect(question.question_responses).to include(response1, response2)
    end

    it 'destroys associated question_responses when destroyed' do
      create(:answer, question: question, correct: true)
      create(:test_categories_test, test: test, test_category: test_category)
      test_attempt = create(:test_attempt, test: test)
      response = create(:question_response, question: question, test_attempt: test_attempt)

      question.destroy

      expect(QuestionResponse.find_by(id: response.id)).to be_nil
    end
  end

  describe 'enums' do
    it 'has question_type enum' do
      question = create(:question, test_category: test_category, question_type: 'multiple_choice')
      expect(question.multiple_choice?).to be(true)
    end
  end

  describe 'scopes' do
    it 'orders by display_order' do
      q1 = create(:question, test_category: test_category, display_order: 3)
      q2 = create(:question, test_category: test_category, display_order: 1)
      q3 = create(:question, test_category: test_category, display_order: 2)

      expect(Question.ordered.pluck(:id)).to eq([q2.id, q3.id, q1.id])
    end

    it 'filters active questions' do
      active_question = create(:question, test_category: test_category, active: true)
      inactive_question = create(:question, test_category: test_category, active: false)

      expect(Question.active).to include(active_question)
      expect(Question.active).not_to include(inactive_question)
    end
  end

  describe 'instance methods' do
    let(:question) { create(:question, test_category: test_category) }

    describe '#multiple_choice?' do
      it 'returns true when question_type is multiple_choice' do
        question = create(:question, test_category: test_category, question_type: 'multiple_choice')
        expect(question.multiple_choice?).to be(true)
      end
    end

    describe '#correct_answers' do
      it 'returns only correct answers' do
        correct_answer1 = create(:answer, question: question, correct: true)
        correct_answer2 = create(:answer, question: question, correct: true)
        incorrect_answer = create(:answer, question: question, correct: false)

        expect(question.correct_answers).to include(correct_answer1, correct_answer2)
        expect(question.correct_answers).not_to include(incorrect_answer)
      end

      it 'returns empty collection when no correct answers exist' do
        create(:answer, question: question, correct: false)
        expect(question.correct_answers).to be_empty
      end
    end

    describe '#correct_answer_ids' do
      it 'returns array of correct answer IDs' do
        correct_answer1 = create(:answer, question: question, correct: true)
        correct_answer2 = create(:answer, question: question, correct: true)
        create(:answer, question: question, correct: false)

        expect(question.correct_answer_ids).to match_array([correct_answer1.id, correct_answer2.id])
      end

      it 'returns empty array when no correct answers exist' do
        create(:answer, question: question, correct: false)
        expect(question.correct_answer_ids).to be_empty
      end
    end

    describe '#correct_answer_count' do
      it 'returns count of correct answers' do
        create(:answer, question: question, correct: true)
        create(:answer, question: question, correct: true)
        create(:answer, question: question, correct: false)

        expect(question.correct_answer_count).to eq(2)
      end

      it 'returns 0 when no correct answers exist' do
        create(:answer, question: question, correct: false)
        expect(question.correct_answer_count).to eq(0)
      end
    end

    describe '#randomize_answers' do
      it 'returns shuffled answers' do
        answer1 = create(:answer, question: question, display_order: 1)
        answer2 = create(:answer, question: question, display_order: 2)
        answer3 = create(:answer, question: question, display_order: 3)

        # Call multiple times to ensure randomization
        shuffled_arrays = 5.times.map { question.randomize_answers.map(&:id) }

        # At least one shuffle should be different from the original order
        original_order = [answer1.id, answer2.id, answer3.id]
        expect(shuffled_arrays.any? { |arr| arr != original_order }).to be(true)
      end

      it 'returns all answers even when shuffled' do
        answer1 = create(:answer, question: question)
        answer2 = create(:answer, question: question)
        answer3 = create(:answer, question: question)

        shuffled = question.randomize_answers
        expect(shuffled.map(&:id).sort).to eq([answer1.id, answer2.id, answer3.id].sort)
      end
    end
  end

  describe 'positioned functionality' do
    it 'positions questions within test_category by display_order' do
      category1 = create(:test_category)
      category2 = create(:test_category)

      q1 = create(:question, test_category: category1, display_order: 1)
      q2 = create(:question, test_category: category1, display_order: 2)
      q3 = create(:question, test_category: category2, display_order: 1)

      # Questions should be ordered within their category
      expect(category1.questions.ordered).to eq([q1, q2])
      expect(category2.questions.ordered).to eq([q3])
    end
  end
end
