require 'rails_helper'

RSpec.describe 'Admin::QuestionsController', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:test_category) { create(:test_category) }
  let(:question) { create(:question, test_category: test_category, display_order: 1) }
  let(:other_question) { create(:question, test_category: test_category, display_order: 2) }

  before { sign_in admin, scope: :user }

  describe 'GET /admin/test_categories/:test_category_id/questions/new' do
    it 'renders the new page' do
      get new_admin_test_category_question_path(test_category)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:question)).to be_a(Question)
    end
  end

  describe 'POST /admin/test_categories/:test_category_id/questions' do
    it 'creates a question and redirects to the test category' do
      question_params = attributes_for(:question)

      expect do
        post admin_test_category_questions_path(test_category), params: { question: question_params }
      end.to change(Question, :count).by(1)

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(flash[:notice]).to eq(I18n.t('admin.questions.created'))
    end

    it 'renders the new page with error when creation fails' do
      question_params = attributes_for(:question, text_et: nil)

      post admin_test_category_questions_path(test_category), params: { question: question_params }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Text et (ET) can't be blank")
    end
  end

  describe 'GET /admin/test_categories/:test_category_id/questions/:id/edit' do
    it 'renders the edit page' do
      get edit_admin_test_category_question_path(test_category, question)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
      expect(assigns(:question)).to be_a(Question)
    end
  end

  describe 'PATCH /admin/test_categories/:test_category_id/questions/:id' do
    it 'updates the question and redirects to the test category' do
      patch admin_test_category_question_path(test_category, question), params: { question: { text_et: 'New text' } }

      expect(response).to redirect_to(admin_test_category_path(test_category))
      expect(question.reload.text_et).to eq('New text')
      expect(flash[:notice]).to eq(I18n.t('admin.questions.updated'))
    end

    it 'renders the edit page with error when update fails' do
      patch admin_test_category_question_path(test_category, question), params: { question: { text_et: nil } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Text et (ET) can't be blank")
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

  describe 'POST /admin/test_categories/:test_category_id/questions/update_positions' do
    it 'updates the positions and redirects to the test category' do
      expect(question.display_order).to eq(1)
      expect(other_question.display_order).to eq(2)
      post update_positions_admin_test_category_questions_path(test_category, format: :json), params: { positions: { question.id => 2 } }

      expect(response).to have_http_status(:no_content)
      expect(question.reload.display_order).to eq(2)
      expect(other_question.reload.display_order).to eq(1)
    end

    it 'renders the update positions page with error when update fails' do
      post update_positions_admin_test_category_questions_path(test_category, format: :json), params: { positions: { 'invalid' => 2 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to eq("Couldn't find Question with 'id'=\"invalid\"")
    end
  end
end
