require 'rails_helper'

RSpec.describe 'Admin::AnswersController', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:test_category) { create(:test_category) }
  let(:question) { create(:question, test_category: test_category) }

  before { sign_in admin, scope: :user }

  describe 'POST /admin/test_categories/:test_category_id/questions/:question_id/answers' do
    it 'creates an answer and redirects back to the test category' do
      answer_params = attributes_for(:answer)

      expect do
        post admin_test_category_question_answers_path(test_category, question), params: { answer: answer_params }
      end.to change(Answer, :count).by(1)

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(flash[:notice]).to eq(I18n.t('admin.answers.created'))
    end
  end

  describe 'PATCH /admin/.../answers/:id' do
    it 'updates the answer and redirects back to the test category' do
      answer = create(:answer, question: question, text_et: 'Old text')

      patch admin_test_category_question_answer_path(test_category, question, answer),
            params: { answer: { text_et: 'New text' } }

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(answer.reload.text_et).to eq('New text')
      expect(flash[:notice]).to eq(I18n.t('admin.answers.updated'))
    end
  end

  describe 'DELETE /admin/.../answers/:id' do
    it 'destroys the answer and redirects back to the test category' do
      answer = create(:answer, question: question)

      expect do
        delete admin_test_category_question_answer_path(test_category, question, answer)
      end.to change(Answer, :count).by(-1)

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(flash[:notice]).to eq(I18n.t('admin.answers.destroyed'))
    end
  end
end
