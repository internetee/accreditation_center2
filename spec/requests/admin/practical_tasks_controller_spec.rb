require 'rails_helper'

RSpec.describe 'Admin::PracticalTasksController', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:test_record) { create(:test, test_type: :practical) }
  let!(:practical_task) { create(:practical_task, test: test_record) }

  before { sign_in admin, scope: :user }

  describe 'GET /admin/tests/:test_id/practical_tasks/new' do
    it 'renders the new page' do
      get new_admin_test_practical_task_path(test_record)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:practical_task)).to be_a(PracticalTask)
    end
  end

  describe 'POST /admin/tests/:test_id/practical_tasks' do
    it 'creates a practical task and redirects to the test' do
      params = attributes_for(:practical_task)

      expect do
        post admin_test_practical_tasks_path(test_record), params: { practical_task: params }
      end.to change(PracticalTask, :count).by(1)

      expect(response).to redirect_to(admin_test_path(test_record))
      expect(flash[:notice]).to eq(I18n.t('admin.practical_tasks.created'))
    end

    it 'renders the new page with error when creation fails' do
      params = attributes_for(:practical_task, body_et: nil)

      post admin_test_practical_tasks_path(test_record), params: { practical_task: params }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Body et (ET) can't be blank")
    end
  end

  describe 'PATCH /admin/tests/:test_id/practical_tasks/:id' do
    it 'updates the task and redirects' do
      patch admin_test_practical_task_path(test_record, practical_task), params: { practical_task: { title_et: 'Updated' } }

      expect(response).to redirect_to(admin_test_path(test_record))
      expect(practical_task.reload.title_et).to eq('Updated')
      expect(flash[:notice]).to eq(I18n.t('admin.practical_tasks.updated'))
    end

    it 'renders the edit page with error when update fails' do
      patch admin_test_practical_task_path(test_record, practical_task), params: { practical_task: { body_et: nil } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Body et (ET) can't be blank")
    end
  end

  describe 'DELETE /admin/tests/:test_id/practical_tasks/:id' do
    it 'destroys the task and redirects' do
      expect do
        delete admin_test_practical_task_path(test_record, practical_task)
      end.to change(PracticalTask, :count).by(-1)

      expect(response).to redirect_to(admin_test_path(test_record))
      expect(flash[:notice]).to eq(I18n.t('admin.practical_tasks.destroyed'))
    end
  end
end
