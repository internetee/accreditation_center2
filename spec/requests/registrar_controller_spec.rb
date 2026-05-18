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

      it 'does not include the registrar colleagues link in the main menu' do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(I18n.t('nav.registrar_colleagues'))
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

      it 'includes a main navigation link to the registrar colleagues page' do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(I18n.t('nav.registrar_colleagues')))
        expect(response.body).to include(registrar_path)
      end

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

      describe 'sorting' do
        def colleague_first_column_cells(html)
          doc = Nokogiri::HTML(html)
          doc.css('table.table--registrar-colleagues tbody tr').filter_map { |tr| tr.at_css('td')&.text&.strip }
        end

        it 'renders sortable column headers like admin tables' do
          get registrar_path

          expect(response.body).to include('sort_link')
          expect(response.body).to include('sort=name')
          expect(response.body).to include('sort=test_type')
        end

        it 'sorts by name descending' do
          get registrar_path, params: { sort: 'name', direction: 'desc' }

          expect(response).to have_http_status(:ok)
          names = colleague_first_column_cells(response.body)
          expect(names).to eq([
                                'Bob Colleague', 'Bob Colleague',
                                'Alice Colleague', 'Alice Colleague'
                              ])
        end

        it 'ignores an unknown sort parameter' do
          get registrar_path

          default_names = colleague_first_column_cells(response.body)

          get registrar_path, params: { sort: 'not_a_column', direction: 'desc' }

          expect(colleague_first_column_cells(response.body)).to eq(default_names)
        end

        it 'preserves sort and direction in the search form' do
          get registrar_path, params: { sort: 'test_type', direction: 'desc' }

          doc = Nokogiri::HTML(response.body)
          sort_field = doc.at_css('input[type="hidden"][name="sort"]')
          direction_field = doc.at_css('input[type="hidden"][name="direction"]')
          expect(sort_field['value']).to eq('test_type')
          expect(direction_field['value']).to eq('desc')
        end
      end

      describe 'latest test attempt projection' do
        let(:theoretical_test) { create(:test, :theoretical, title_en: 'Theory Test', title_et: 'Teooria Test') }
        let(:practical_test) { create(:test, :practical, title_en: 'Practical Exam', title_et: 'Praktiline eksam') }

        before do
          # Avoid invariants on test_attempt creation that depend on real questions/answers.
          allow_any_instance_of(TestAttempt).to receive(:questions_have_answers).and_return(true)
        end

        it 'shows latest theoretical and practical attempts independently' do
          create(:test_attempt, :passed, user: colleague_same_registrar, test: theoretical_test,
                                         completed_at: 2.days.ago)
          create(:test_attempt, :completed, user: colleague_same_registrar, test: practical_test, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Theory Test')
          expect(response.body).to include('Practical Exam')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.passed'))
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.failed'))
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

        it 'shows a time-expired badge for an attempt whose time limit lapsed without completion' do
          # Started well before the test's time limit elapsed, never completed.
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: (theoretical_test.time_limit_minutes + 10).minutes.ago,
                                completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-danger')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.time_expired'))
          expect(response.body).to include(I18n.t('registrar.show.workflow_completed'))
        end

        it 'prefers a completed attempt over a newer time-expired attempt' do
          # An older passed attempt and a newer attempt that ran out of time
          # without being completed: completed should still win.
          create(:test_attempt, :passed, user: colleague_same_registrar, test: theoretical_test,
                                         completed_at: 10.days.ago)
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: (theoretical_test.time_limit_minutes + 10).minutes.ago,
                                completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-success')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.passed'))
          expect(response.body).not_to include(I18n.t('admin.test_attempts.test_attempts_table.time_expired'))
        end

        it 'prefers an active in-progress attempt over a time-expired one' do
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: (theoretical_test.time_limit_minutes + 10).minutes.ago,
                                completed_at: nil, passed: false)
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: 5.minutes.ago, completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-warning')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.in_progress'))
          expect(response.body).not_to include(I18n.t('admin.test_attempts.test_attempts_table.time_expired'))
        end

        it 'prefers a time-expired attempt over a newer not-started attempt' do
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: (theoretical_test.time_limit_minutes + 10).minutes.ago,
                                completed_at: nil, passed: false)
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: nil, completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.time_expired'))
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

        it 'prefers a completed attempt over a newer not-started attempt' do
          # An older completed attempt and a newer assigned-but-untouched one.
          create(:test_attempt, :passed, user: colleague_same_registrar, test: theoretical_test,
                                         completed_at: 10.days.ago)
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: nil, completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-success')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.passed'))
        end

        it 'prefers an in-progress attempt over a newer not-started attempt' do
          # Must stay within theoretical_test.time_limit_minutes (factory default 60)
          # or the attempt is time-expired, not in progress.
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: 10.minutes.ago, completed_at: nil, passed: false)
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: nil, completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('badge-warning')
          expect(response.body).to include(I18n.t('admin.test_attempts.test_attempts_table.in_progress'))
        end

        it 'falls back to not-started when only not-started attempts exist for the colleague' do
          create(:test_attempt, user: colleague_same_registrar, test: theoretical_test,
                                started_at: nil, completed_at: nil, passed: false)

          get registrar_path

          expect(response).to have_http_status(:ok)
          # Neither colleague has a started or completed attempt, so no
          # success/danger/warning badges should be rendered.
          expect(response.body).not_to include('badge-success')
          expect(response.body).not_to include('badge-danger')
          expect(response.body).not_to include('badge-warning')
          expect(response.body).to include('badge-default')
          # The assigned (but not started) test is still shown in the table.
          expect(response.body).to include('Theory Test')
        end

        it 'ignores attempts that belong to users from other registrars' do
          other_test = create(:test, :theoretical, title_en: 'Other Test', title_et: 'Other Test')
          create(:test_attempt, :passed, user: other_registrar_user, test: other_test)

          get registrar_path

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include('Other Test')
        end
      end

      describe 'search' do
        let(:search_test) { create(:test, :theoretical, title_en: 'ZetaUniqueTitle', title_et: 'Zeta') }

        before do
          allow_any_instance_of(TestAttempt).to receive(:questions_have_answers).and_return(true)
        end

        it 'returns only rows matching the query' do
          create(:test_attempt, :passed, user: colleague_same_registrar, test: search_test)

          get registrar_path, params: { q: 'ZetaUniqueTitle' }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('ZetaUniqueTitle')
          expect(response.body).to include('Bob Colleague')
          expect(response.body).not_to include(I18n.t('registrar.show.search_no_results'))
        end

        it 'shows a no-results message when the query matches nothing' do
          get registrar_path, params: { q: 'no_such_match_xyz_12345' }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t('registrar.show.search_no_results'))
          expect(response.body).not_to include('table--registrar-colleagues')
        end

        it 'matches status keywords' do
          create(:test_attempt, :passed, user: colleague_same_registrar, test: search_test)

          get registrar_path, params: { q: 'passed' }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Bob Colleague')
          expect(response.body).not_to include(I18n.t('registrar.show.search_no_results'))
        end
      end
    end
  end
end
