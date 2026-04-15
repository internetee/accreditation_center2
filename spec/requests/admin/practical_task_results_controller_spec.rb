require 'rails_helper'

RSpec.describe 'Admin::PracticalTaskResultsController', type: :request do
  let(:admin) { create(:user, :admin, name: 'Admin Reviewer') }
  let(:regular_user) { create(:user) }
  let(:test_record) { create(:test, :practical) }
  let(:attempt) { create(:test_attempt, user: regular_user, test: test_record, started_at: 10.minutes.ago, completed_at: nil) }
  let(:task) { create(:practical_task, test: test_record) }
  let!(:result_record) do
    create(
      :practical_task_result,
      test_attempt: attempt,
      practical_task: task,
      status: 'pending',
      result: {}
    )
  end

  before { sign_in(admin, scope: :user) }

  describe 'GET /admin/tests/:test_id/practical_tasks/:practical_task_id/practical_task_results' do
    it 'renders index with results' do
      get admin_test_practical_task_practical_task_results_path(test_record, task)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:practical_task_results)).to include(result_record)
    end
  end

  describe 'GET /admin/tests/:test_id/practical_tasks/:practical_task_id/practical_task_results/:id' do
    it 'renders show and assigns context' do
      get admin_test_practical_task_practical_task_result_path(test_record, task, result_record)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
      expect(assigns(:test_attempt)).to eq(attempt)
      expect(assigns(:user)).to eq(regular_user)
    end
  end

  describe 'PATCH /admin/tests/:test_id/practical_tasks/:practical_task_id/practical_task_results/:id' do
    it 'updates status and feedback when attempt is in progress' do
      patch admin_test_practical_task_practical_task_result_path(test_record, task, result_record),
            params: { practical_task_result: { status: 'failed', feedback: 'Needs correction' } }

      expect(response).to redirect_to(admin_test_practical_task_practical_task_result_path(test_record, task, result_record))
      expect(flash[:notice]).to eq(I18n.t('admin.practical_task_results.updated'))
      expect(result_record.reload.status).to eq('failed')
      expect(result_record.feedback).to eq('Needs correction')
      expect(result_record.feedback_by_name).to eq('Admin Reviewer')
    end

    it 'blocks status/feedback changes when attempt is completed' do
      attempt.update!(completed_at: Time.current)

      patch admin_test_practical_task_practical_task_result_path(test_record, task, result_record),
            params: { practical_task_result: { status: 'passed', feedback: 'Looks good' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:show)
      expect(flash[:alert]).to eq(I18n.t('admin.practical_task_results.show.feedback_locked_after_completion'))
      expect(result_record.reload.status).to eq('pending')
      expect(result_record.feedback).to be_nil
    end
  end

  describe 'authorization' do
    it 'redirects non-admin user to root path' do
      sign_out :user
      sign_in(regular_user, scope: :user)

      get admin_test_practical_task_practical_task_results_path(test_record, task)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
    end
  end
end
