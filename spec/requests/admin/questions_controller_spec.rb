require 'rails_helper'

RSpec.describe 'Admin::QuestionsController', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:test_category) { create(:test_category) }
  let(:question) { create(:question, test_category: test_category) }

  before { sign_in admin, scope: :user }

  describe 'POST /admin/test_categories/:test_category_id/questions' do
    it 'creates a question and redirects to the test category' do
      question_params = attributes_for(:question)

      expect do
        post admin_test_category_questions_path(test_category), params: { question: question_params }
      end.to change(Question, :count).by(1)

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(flash[:notice]).to eq(I18n.t('admin.questions.created'))
    end
  end

  describe 'PATCH /admin/test_categories/:test_category_id/questions/:id' do
    it 'updates the question and redirects to the test category' do
      patch admin_test_category_question_path(test_category, question), params: { question: { text_et: 'New text' } }

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(question.reload.text_et).to eq('New text')
      expect(flash[:notice]).to eq(I18n.t('admin.questions.updated'))
    end
  end

  describe 'DELETE /admin/test_categories/:test_category_id/questions/:id' do
    it 'destroys the question and redirects to the test category' do
      question

      expect do
        delete admin_test_category_question_path(test_category, question)
      end.to change(Question, :count).by(-1)

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(flash[:notice]).to eq(I18n.t('admin.questions.destroyed'))
    end
  end
end
