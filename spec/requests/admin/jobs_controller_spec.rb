require 'rails_helper'

RSpec.describe 'Admin::JobsController', type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }

  before do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
  end

  after { clear_enqueued_jobs }

  describe 'GET /admin/jobs' do
    it 'renders the jobs index for admin users' do
      sign_in(admin, scope: :user)

      get admin_jobs_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it 'redirects non-admin users to root path' do
      sign_in(create(:user), scope: :user)

      get admin_jobs_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
    end
  end

  describe 'POST /admin/jobs/accreditation_sync' do
    it 'enqueues AccreditationSyncJob when registrar is valid' do
      sign_in(admin, scope: :user)
      registrar = create(:registrar)

      expect do
        post accreditation_sync_admin_jobs_path, params: { registrar_id: registrar.id }
      end.to have_enqueued_job(AccreditationSyncJob).with(registrar)

      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to eq(
        I18n.t('admin.jobs.accreditation_sync.enqueued', default: 'Accreditation sync job was enqueued.')
      )
    end

    it 'does not enqueue job when registrar is invalid' do
      sign_in(admin, scope: :user)

      expect do
        post accreditation_sync_admin_jobs_path, params: { registrar_id: -1 }
      end.not_to have_enqueued_job(AccreditationSyncJob)

      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:alert]).to eq(
        I18n.t('admin.jobs.accreditation_sync.invalid_registrar', default: 'Please choose a valid registrar.')
      )
    end
  end

  describe 'POST /admin/jobs/expiry_check' do
    it 'enqueues ExpiryCheckJob with provided reference date' do
      sign_in(admin, scope: :user)
      reference_date = Date.new(2026, 4, 27)

      expect do
        post expiry_check_admin_jobs_path, params: { reference_date: reference_date.iso8601 }
      end.to have_enqueued_job(ExpiryCheckJob).with(reference_date)

      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to eq(
        I18n.t('admin.jobs.expiry_check.enqueued', default: 'Expiry check job was enqueued.')
      )
    end

    it 'enqueues ExpiryCheckJob with today when reference date is blank' do
      sign_in(admin, scope: :user)
      travel_to(Time.zone.local(2026, 4, 27, 12, 0, 0)) do
        expect do
          post expiry_check_admin_jobs_path, params: { reference_date: '' }
        end.to have_enqueued_job(ExpiryCheckJob).with(Date.new(2026, 4, 27))
      end

      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to eq(
        I18n.t('admin.jobs.expiry_check.enqueued', default: 'Expiry check job was enqueued.')
      )
    end

    it 'does not enqueue job when reference date is invalid' do
      sign_in(admin, scope: :user)

      expect do
        post expiry_check_admin_jobs_path, params: { reference_date: 'not-a-date' }
      end.not_to have_enqueued_job(ExpiryCheckJob)

      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:alert]).to eq(
        I18n.t('admin.jobs.expiry_check.invalid_date', default: 'Please enter a valid date.')
      )
    end
  end
end
