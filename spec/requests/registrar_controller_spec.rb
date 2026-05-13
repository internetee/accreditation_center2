require 'rails_helper'

RSpec.describe 'RegistrarController', type: :request do
  describe 'GET /registrar' do
    context 'when not signed in' do
      it 'redirects to the user sign-in page' do
        get registrar_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in as admin' do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin, scope: :user) }

      it 'redirects to the admin dashboard with an access denied message' do
        get registrar_path

        expect(response).to redirect_to(admin_dashboard_path)
        expect(flash[:alert]).to eq(I18n.t(:access_denied_admin))
      end

      it 'does not block admin registrar management routes' do
        registrar = create(:registrar)
        create(:user, registrar: registrar)

        get admin_registrar_path(registrar)

        expect(response).to have_http_status(:ok)
        expect(response).to render_template('admin/registrars/show')
      end
    end

    context 'when signed in as a regular user without a registrar' do
      let(:user) { create(:user, registrar_name: nil) }

      before { sign_in(user, scope: :user) }

      it 'responds successfully and shows the missing-registrar message' do
        expect(user.reload.registrar).to be_nil

        get registrar_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to include(I18n.t('registrar.show.no_registrar'))
        expect(response.body).not_to include('table--striped')
      end
    end

    context 'when signed in as a regular user with a registrar' do
      let(:registrar_a) { create(:registrar, name: 'Registrar Alpha') }
      let(:registrar_b) { create(:registrar, name: 'Registrar Beta') }
      let(:current_user) { create(:user, registrar: registrar_a, name: 'Alice Colleague', email: 'alice@example.test') }
      let!(:colleague_same_registrar) { create(:user, registrar: registrar_a, name: 'Bob Colleague', email: 'bob@example.test') }
      let!(:other_registrar_user) { create(:user, registrar: registrar_b, name: 'Carol Other', email: 'carol@example.test') }
      let!(:admin_same_registrar) do
        create(:user, :admin, registrar: registrar_a, email: 'admin-on-alpha@example.test')
      end

      before { sign_in(current_user, scope: :user) }

      it 'renders colleagues from the same registrar only and excludes admins' do
        get registrar_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to include('Registrar Alpha')
        expect(response.body).to include('Alice Colleague')
        expect(response.body).to include('Bob Colleague')
        expect(response.body).not_to include('Carol Other')
        expect(response.body).not_to include('carol@example.test')
        expect(response.body).not_to include(admin_same_registrar.email)
      end

      describe 'latest test attempt projection' do
        let(:theoretical_test) { create(:test, :theoretical, title_en: 'Theory Test', title_et: 'Teooria Test') }

        before do
          # Avoid invariants on test_attempt creation that depend on real questions/answers.
          allow_any_instance_of(TestAttempt).to receive(:questions_have_answers).and_return(true)
        end

        it 'shows a passed badge and completed-at date for the latest attempt' do
          completed_at = Time.zone.local(2026, 5, 1, 10, 0)
          create(:test_attempt, :passed, user: colleague_same_registrar, test: theoretical_test,
                                         completed_at: completed_at)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-success')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.passed'))
          expect(response.body).to include(I18n.t('registrar.show.workflow_completed'))
          expect(response.body).to include(I18n.l(completed_at, format: :short))
          expect(response.body).to include('Theory Test')
        end

        it 'shows a failed badge for the latest completed-but-not-passed attempt' do
          create(:test_attempt, :completed, user: colleague_same_registrar, test: theoretical_test, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-danger')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.failed'))
        end

        it 'shows an in-progress badge for an attempt that has been started but not completed' do
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: Time.current, completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-warning')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.in_progress'))
          expect(response.body).to include(I18n.t('registrar.show.workflow_in_progress'))
        end

        it 'shows a not-started badge for users without any attempts' do
          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-default')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.not_started'))
          expect(response.body).to include(I18n.t('registrar.show.workflow_not_started'))
        end

        it 'uses the most recent attempt when a colleague has multiple attempts' do
          create(:test_attempt, :completed, user: colleague_same_registrar, test: theoretical_test,
                                            passed: false, completed_at: 10.days.ago)
          create(:test_attempt, :passed, user: colleague_same_registrar, test: theoretical_test,
                                         completed_at: 1.day.ago)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-success')
          expect(response.body).not_to include('badge-danger')
        end

        it 'ignores attempts that belong to users from other registrars' do
          other_test = create(:test, :theoretical, title_en: 'Other Test', title_et: 'Other Test')
          create(:test_attempt, :passed, user: other_registrar_user, test: other_test)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include('Other Test')
        end
      end
    end
  end
end
