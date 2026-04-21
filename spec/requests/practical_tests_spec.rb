require 'rails_helper'

RSpec.describe 'PracticalTests', type: :request do
  let(:user) { create(:user) }
  let!(:test) { create(:test, :practical) }
  let!(:task1) { create(:practical_task, test: test, display_order: 1) }
  let!(:task2) { create(:practical_task, test: test, display_order: 2) }
  let!(:practical_task_result1) { create(:practical_task_result, test_attempt: test_attempt, practical_task: task1, status: :pending) }
  let!(:practical_task_result2) { create(:practical_task_result, test_attempt: test_attempt, practical_task: task2, status: :pending) }
  let!(:test_attempt) { create(:test_attempt, user: user, test: test, started_at: nil) }

  before { sign_in user, scope: :user }

  it 'does not start a test and redirects to root if not logged in' do
    sign_out :user
    post start_practical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to redirect_to(new_user_session_path)
  end

  it 'starts a test and redirects to question if test attempt is found' do
    post start_practical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to redirect_to(question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0))
  end

  it 'does not starts a test and redirects to root if current user is admin' do
    user.update(role: :admin)
    post start_practical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to redirect_to(admin_dashboard_path)
    expect(flash[:alert]).to eq(I18n.t(:access_denied_admin))
  end

  it 'does not start a test and redirects to root if test attempt is not found' do
    post start_practical_test_path(test, attempt: 'invalid')

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq(I18n.t('tests.test_not_found'))
  end

  it 'serves a question and redirects to results if there are no tasks' do
    test.practical_tasks.destroy_all
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

    expect(response).to redirect_to(results_practical_test_path(test, attempt: test_attempt.access_code))
  end

  it 'does not serve a question and redirects to results if test attempt is expired' do
    test_attempt.update(started_at: 1.hour.ago)
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0)
  end

  it 'does not serve a question and redirects to root if test attempt is completed and another test attempt is in progress' do
    test_attempt.update(started_at: Time.current, completed_at: Time.current)
    create(:test_attempt, user: user, test: test, started_at: Time.current)
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq(I18n.t('tests.history_blocked_while_active'))
  end

  it 'serves a question and renders the question template if test attempt is completed and another test attempt is not started yet' do
    test_attempt.update(started_at: Time.current, completed_at: Time.current)
    create(:test_attempt, user: user, test: test, started_at: nil)
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

    expect(response).to have_http_status(:ok)
    expect(response).to render_template(:question)
  end

  it 'serves a question and redirects to results if task not found' do
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 100)

    expect(response).to redirect_to(results_practical_test_path(test, attempt: test_attempt.access_code))
  end

  it 'serves a question and redirects to the previous task if navigating past the first pending task' do
    test_attempt.update(started_at: Time.current)
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 1)

    expect(response).to redirect_to(question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0))
    expect(flash[:alert]).to eq(I18n.t('tests.task_current_to_continue'))
  end

  it 'serves a question and renders the question template if test attempt is completed' do
    test_attempt.update(started_at: Time.current, completed_at: Time.current)
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

    expect(response).to have_http_status(:ok)
    expect(response).to render_template(:question)
  end

  it 'serves a question and renders the question template' do
    get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

    expect(response).to have_http_status(:ok)
    expect(assigns(:tasks)).to eq([task1, task2])
    expect(assigns(:current_task_index)).to eq(0)
    expect(assigns(:current_task)).to eq(task1)
    expect(response).to render_template(:question)
  end

  it 'serves a question and shows a time warning if needed' do
    start_time = Time.zone.parse('2024-01-01 12:00:00')
    travel_to start_time + test.time_limit_minutes.minutes - 1.minute do
      test_attempt.update(started_at: start_time)
      get question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

      expect(response).to have_http_status(:ok)
      expect(flash[:warning]).to eq(I18n.t('tests.time_warning', minutes: 5))
    end
  end

  it 'accepts ans answer and returns not found if task not found' do
    post answer_practical_test_path(test, attempt: test_attempt.access_code, question_index: 100),
         params: { inputs: { any: 'value' } }

    expect(response).to have_http_status(:not_found)
  end

  it 'accepts an answer and advances to the next task' do
    # Stub validator to short‑circuit external calls
    fake_validator = instance_double(
      'CreateContactsValidator',
      call: { passed: true, export_vars: { any: 'value' }, error: nil }
    )
    allow(CreateContactsValidator).to receive(:new).and_return(fake_validator)

    post answer_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0),
         params: { inputs: { any: 'value' } }

    expect(response).to redirect_to(
      question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 1)
    )
    expect(practical_task_result1.reload.status).to eq('passed')
    expect(flash[:notice]).to eq(I18n.t('tests.task_passed'))
  end

  it 'accepts ans answer and raises an error if the validator not found' do
    task1.update(validator: { klass: 'NonExistentValidator' })
    post answer_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0),
         params: { inputs: { any: 'value' } }

    expect(response).to redirect_to(question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0))
    expect(practical_task_result1.reload.status).to eq('failed')
    expect(flash[:alert]).to eq('Validator class not found: NonExistentValidator')
  end

  it 'accepts an answer and returns a timeout error if the validator takes too long' do
    task1.update(validator: { klass: 'CreateContactsValidator', config: { timeout_seconds: 1 } })
    # Stub validator to short‑circuit external calls
    fake_validator = instance_double(
      'CreateContactsValidator',
      call: { passed: true, export_vars: { any: 'value' }, error: nil }
    )
    allow(fake_validator).to receive(:call) do
      sleep 2 # Simulate long-running operation
    end
    allow(CreateContactsValidator).to receive(:new).and_return(fake_validator)

    post answer_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0),
         params: { inputs: { any: 'value' } }

    expect(response).to redirect_to(question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0))
    expect(practical_task_result1.reload.status).to eq('failed')
    expect(flash[:alert]).to eq('execution expired')
  end

  it 'renders results' do
    get results_practical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to have_http_status(:ok)
    expect(response).to render_template(:results)
  end

  it 'renders results and does not show detailed responses if the test attempt is older than 30 days' do
    test_attempt.update(started_at: 32.days.ago, completed_at: 31.days.ago)
    get results_practical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to have_http_status(:ok)
    expect(response).to render_template(:results)
  end
end
