require 'rails_helper'

RSpec.describe 'Admin::TestAttemptsController', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:test_record) { create(:test) }
  let(:user) { create(:user) }
  let!(:test_category) { create(:test_category) }
  let!(:question) { create(:question, test_category: test_category) }
  let!(:answer) { create(:answer, question: question, correct: true) }
  let!(:test_categories_test) { create(:test_categories_test, test: test_record, test_category: test_category) }
  let!(:test_attempt) { create(:test_attempt, test: test_record, user: user) }

  before { sign_in(admin, scope: :user) }

  describe 'GET /admin/tests/:test_id/test_attempts' do
    it 'renders the index successfully' do
      get admin_test_test_attempts_path(test_record)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:test_attempts)).to include(test_attempt)
    end
  end

  describe 'GET /admin/tests/:test_id/test_attempts/new' do
    it 'renders the new page' do
      get new_admin_test_test_attempt_path(test_record)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:users)).not_to include(user)
    end
  end

  describe 'GET /admin/tests/:test_id/test_attempts/:id' do
    it 'renders the show page' do
      get admin_test_test_attempt_path(test_record, test_attempt)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
      expect(assigns(:question_responses)).to eq(test_attempt.question_responses.includes(:question, :answers))
    end

    it 'assigns practical task results in creation order matching practical task sequence' do
      practical_test = create(:test, :practical)
      practical_attempt = create(:test_attempt, test: practical_test, user: user)
      first_task = create(:practical_task, test: practical_test, display_order: 1)
      second_task = create(:practical_task, test: practical_test, display_order: 2)

      first_result = create(:practical_task_result, test_attempt: practical_attempt, practical_task: first_task, status: 'passed')
      second_result = create(:practical_task_result, test_attempt: practical_attempt, practical_task: second_task, status: 'failed')

      get admin_test_test_attempt_path(practical_test, practical_attempt)

      expect(response).to have_http_status(:ok)
      expect(assigns(:practical_task_results).pluck(:id)).to eq([first_result.id, second_result.id])
      expect(assigns(:practical_task_results).pluck(:practical_task_id)).to eq([first_task.id, second_task.id])
    end
  end

  describe 'POST /admin/tests/:test_id/test_attempts' do
    it 'assigns the test and redirects' do
      new_user = create(:user)

      allow(Attempts::Assign).to receive(:call!).and_call_original

      expect do
        post admin_test_test_attempts_path(test_record), params: { test_attempt: { user_id: new_user.id } }
      end.to change(TestAttempt, :count).by(1)

      expect(response).to redirect_to(admin_test_test_attempts_path(test_record))
      expect(flash[:notice]).to eq(I18n.t('admin.test_attempts.assigned'))
    end

    it 'renders the new page with error when assignment fails' do
      new_user = create(:user)

      allow(Attempts::Assign).to receive(:call!).and_raise(StandardError, 'Assignment failed')

      post admin_test_test_attempts_path(test_record), params: { test_attempt: { user_id: new_user.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
      expect(flash[:alert]).to eq('Error assigning test: Assignment failed')
    end
  end

  describe 'PATCH /admin/tests/:test_id/test_attempts/:id/extend_time' do
    context 'when attempt is in progress' do
      let!(:test_attempt) { create(:test_attempt, test: test_record, user: user, started_at: Time.current, completed_at: nil) }

      it 'extends the timer and redirects' do
        expect { patch extend_time_admin_test_test_attempt_path(test_record, test_attempt) }
          .to(change { test_attempt.reload.started_at })

        expect(response).to redirect_to(admin_test_test_attempts_path(test_record))
        expect(flash[:notice]).to eq(I18n.t('admin.test_attempts.time_extended'))
      end
    end

    context 'when attempt is not in progress' do
      let!(:test_attempt) { create(:test_attempt, test: test_record, user: user, started_at: nil, completed_at: nil) }

      it 'does not extend time and shows alert' do
        patch extend_time_admin_test_test_attempt_path(test_record, test_attempt)

        expect(response).to redirect_to(admin_test_test_attempts_path(test_record))
        expect(flash[:alert]).to eq(I18n.t('admin.test_attempts.cannot_extend_time'))
      end
    end
  end

  describe 'DELETE /admin/tests/:test_id/test_attempts/:id' do
    it 'deletes the attempt and redirects' do
      expect do
        delete admin_test_test_attempt_path(test_record, test_attempt)
      end.to change(TestAttempt, :count).by(-1)

      expect(response).to redirect_to(admin_test_test_attempts_path(test_record))
      expect(flash[:notice]).to eq(I18n.t('admin.test_attempts.removed'))
    end
  end
end
