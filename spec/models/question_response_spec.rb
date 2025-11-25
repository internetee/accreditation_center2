require 'rails_helper'

RSpec.describe QuestionResponse, type: :model do
  let(:test_category) { create(:test_category) }
  let(:question) { create(:question, test_category: test_category) }
  let(:user) { create(:user) }
  let(:test_record) { create(:test, :theoretical) }
  let!(:test_categories_test) { create(:test_categories_test, test: test_record, test_category: test_category) }
  let!(:question) { create(:question, test_category: test_category) }
  let!(:answer) { create(:answer, question: question, correct: true) }
  let(:attempt) { create(:test_attempt, user: user, test: test_record) }

  describe 'validations' do
    it 'requires selected_answer_ids on update unless marked_for_later' do
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [])

      # For persisted records, on: :update validations run on valid? as well
      qr.selected_answer_ids = []
      expect(qr.valid?).to be(false)
      expect(qr.errors[:base]).to eq([I18n.t('tests.select_answer_or_marked_for_later')])

      # Saving should also fail without selection
      expect(qr.update(selected_answer_ids: [])).to be(false)
      expect(qr.errors[:base]).to eq([I18n.t('tests.select_answer_or_marked_for_later')])

      # when marked_for_later, it should allow empty
      qr.marked_for_later = true
      qr.selected_answer_ids = []
      expect(qr.valid?).to be(true)
      expect(qr.update(marked_for_later: true, selected_answer_ids: [])).to be(true)
    end
  end

  describe 'scopes and ordering' do
    it 'default orders by created_at asc and answered scope filters properly' do
      q1 = create(:question, test_category: test_category)
      q2 = create(:question, test_category: test_category)
      q3 = create(:question, test_category: test_category)

      r1 = create(:question_response, question: q1, test_attempt: attempt, selected_answer_ids: [])
      r2 = create(:question_response, question: q2, test_attempt: attempt, selected_answer_ids: [999])
      r3 = create(:question_response, question: q3, test_attempt: attempt, selected_answer_ids: [888], marked_for_later: true)

      expect(QuestionResponse.all.to_a).to eq([r1, r2, r3])
      expect(QuestionResponse.answered).to contain_exactly(r2)
    end
  end

  describe 'selection helpers' do
    it 'returns selected_answers for selected_answer_ids' do
      a1 = create(:answer, question: question)
      a2 = create(:answer, question: question)
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [a1.id, a2.id])

      expect(qr.selected_answers).to match_array([a1, a2])
    end
  end

  describe 'correctness helpers' do
    let!(:wrong_a) { create(:answer, question: question, correct: false) }

    it 'correct? returns false when marked_for_later' do
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [answer.id], marked_for_later: true)
      expect(qr.correct?).to be(false)
    end

    it 'correct? returns false when no selection' do
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [])
      expect(qr.correct?).to be(false)
    end

    it 'correct? returns true when exactly matches correct answer set' do
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [answer.id])
      expect(qr.correct?).to be(true)
    end

    it 'partially_correct? returns true when subset of correct answers and no incorrect selected' do
      answer2 = create(:answer, question: question, correct: true)
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [answer.id, answer2.id])
      expect(qr.partially_correct?).to be(true)
    end

    it 'partially_correct? returns false when includes incorrect selection' do
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [wrong_a.id])
      expect(qr.partially_correct?).to be(false)
    end

    it 'answered? reflects presence of selections' do
      q1 = create(:question, test_category: test_category)
      q2 = create(:question, test_category: test_category)
      qr1 = create(:question_response, question: q1, test_attempt: attempt, selected_answer_ids: [])
      qr2 = create(:question_response, question: q2, test_attempt: attempt, selected_answer_ids: [answer.id])
      expect(qr1.answered?).to be(false)
      expect(qr2.answered?).to be(true)
    end
  end

  describe 'status' do
    it "returns 'marked_for_later' when marked and attempt in progress" do
      attempt.update!(started_at: Time.zone.now, completed_at: nil)
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [1], marked_for_later: true)
      expect(qr.status).to eq('marked_for_later')
    end

    it "returns 'correct' when correct and attempt completed" do
      a = create(:answer, question: question, correct: true)
      attempt.update!(started_at: Time.zone.now - 5.minutes, completed_at: Time.zone.now)
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [a.id])

      # Ensure correct set matches
      question.answers.where.not(id: a.id).update_all(correct: false)
      expect(qr.correct?).to be(true)
      expect(qr.status).to eq('correct')
    end

    it "returns 'incorrect' when not correct and attempt completed" do
      a_wrong = create(:answer, question: question, correct: false)
      attempt.update!(started_at: Time.zone.now - 5.minutes, completed_at: Time.zone.now)
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [a_wrong.id])
      expect(qr.correct?).to be(false)
      expect(qr.status).to eq('incorrect')
    end

    it "returns 'correct' when answered and attempt not completed" do
      a = create(:answer, question: question)
      attempt.update!(started_at: Time.zone.now, completed_at: nil)
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [a.id])
      expect(qr.completed_at).to be_nil if qr.respond_to?(:completed_at)
      expect(qr.status).to eq('correct')
    end

    it "returns 'unanswered' otherwise" do
      attempt.update!(started_at: nil, completed_at: nil)
      qr = create(:question_response, question: question, test_attempt: attempt, selected_answer_ids: [])
      expect(qr.status).to eq('unanswered')
    end
  end
end
