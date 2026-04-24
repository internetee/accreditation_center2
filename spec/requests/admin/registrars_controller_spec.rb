require 'rails_helper'

RSpec.describe 'Admin::RegistrarsController', type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in(admin, scope: :user) }

  describe 'GET /admin/registrars' do
    it 'renders the registrars index with accreditation statuses' do
      active_registrar = create(:registrar, name: 'Active Registrar', email: 'active@example.test', accreditation_expire_date: 90.days.from_now)
      expiring_registrar = create(:registrar, name: 'Expiring Registrar', email: 'expiring@example.test', accreditation_expire_date: 7.days.from_now)
      expired_registrar = create(:registrar, name: 'Expired Registrar', email: 'expired@example.test', accreditation_expire_date: 1.day.ago)
      no_accreditation_registrar = create(:registrar, name: 'No Accreditation Registrar', email: 'none@example.test', accreditation_expire_date: nil)

      create(:user, registrar: active_registrar)
      create(:user, registrar: expiring_registrar)
      create(:user, registrar: expired_registrar)
      create(:user, registrar: no_accreditation_registrar)

      get admin_registrars_path

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(response.body).to include('Active Registrar')
      expect(response.body).to include('active@example.test')
      expect(response.body).to include('Accredited')
      expect(response.body).to include('Expiring Registrar')
      expect(response.body).to include('Expires soon')
      expect(response.body).to include('Expired Registrar')
      expect(response.body).to include('Expired')
      expect(response.body).to include('No Accreditation Registrar')
      expect(response.body).to include('No accreditation')
    end
  end

  describe 'GET /admin/registrars/:id' do
    it 'renders show for registrar' do
      registrar = create(:registrar, name: 'Registrar Detail', email: 'detail@example.test', accreditation_expire_date: 10.days.from_now)
      user = create(:user, registrar: registrar)

      get admin_registrar_path(registrar)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
      expect(response.body).to include('Registrar Detail')
      expect(response.body).to include('detail@example.test')
      expect(response.body).to include(user.display_name)
    end

    it 'redirects to index when registrar does not exist' do
      get admin_registrar_path(id: 0)

      expect(response).to redirect_to(admin_registrars_path)
      expect(flash[:alert]).to eq(I18n.t('errors.object_not_found'))
    end

    it 'redirects non-admin users to root path' do
      sign_out :user
      sign_in(create(:user), scope: :user)

      registrar = create(:registrar)
      get admin_registrar_path(registrar)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
    end
  end
end
