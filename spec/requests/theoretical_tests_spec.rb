require 'rails_helper'

RSpec.describe 'TheoreticalTests', type: :request do
  let(:user) { create(:user) }
  let(:test) { create(:test, :theoretical) }
  let(:test_attempt) { create(:test_attempt, user: user, test: test, started_at: nil) }

  before { sign_in user, scope: :user }

  it 'does not start a test and redirects to root if not logged in' do
    sign_out :user
    post start_theoretical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to redirect_to(new_user_session_path)
  end

  it 'starts a test and redirects to question if test attempt is found' do
    post start_theoretical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to redirect_to(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0))
    expect(test_attempt.reload.started_at).to be_present
    expect(test_attempt.question_responses.count).to eq(test.test_categories.active.count)
  end

  it 'does not starts a test and redirects to root if current user is admin' do
    user.update(role: :admin)
    post start_theoretical_test_path(test, attempt: test_attempt.access_code)

    expect(response).to redirect_to(admin_dashboard_path)
    expect(flash[:alert]).to eq(I18n.t(:access_denied_admin))
  end

  it 'does not start a test and redirects to root if test attempt is not found' do
    post start_theoretical_test_path(test, attempt: 'invalid')

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq(I18n.t('tests.test_not_found'))
  end

  it 'serves a question and redirects to results if there are no questions' do
    get question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

    expect(response).to redirect_to(results_theoretical_test_path(test, attempt: test_attempt.access_code))
  end

  context 'when questions are present' do
    let!(:test_category) { create(:test_category) }
    let!(:question1) { create(:question, test_category: test_category) }
    let!(:question2) { create(:question, test_category: test_category) }
    let!(:question_response1) { create(:question_response, test_attempt: test_attempt, question: question1, selected_answer_ids: []) }
    let!(:question_response2) { create(:question_response, test_attempt: test_attempt, question: question2, selected_answer_ids: []) }

    before do
      TestCategoriesTest.create!(test: test, test_category: test_category)
    end

    it 'does not serve a question and redirects to results if test attempt is expired' do
      test_attempt.update(started_at: 1.hour.ago)
      get question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

      expect(response).to redirect_to(results_theoretical_test_path(test, attempt: test_attempt.access_code))
      expect(flash[:alert]).to eq(I18n.t('tests.time_expired'))
    end

    it 'does not serve a question and redirects to root if another test attempt is in progress' do
      test_attempt.update(started_at: Time.current)
      create(:test_attempt, user: user, test: test, started_at: Time.current)
      get question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t('tests.history_blocked_while_active'))
    end

    it 'serves a question and redirects to the previous question if the question index is greater than the number of questions' do
      test_attempt.update(started_at: Time.current)
      get question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 1)

      expect(response).to redirect_to(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0))
      expect(flash[:alert]).to eq(I18n.t('tests.answer_current_to_continue'))
    end

    it 'serves a question and renders the question template' do
      test_attempt.update(started_at: Time.current)
      get question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

      expect(response).to have_http_status(:ok)
      expect(assigns(:questions)).to eq([question1, question2])
      expect(assigns(:current_question_index)).to eq(0)
      expect(assigns(:current_question)).to eq(question1)
      expect(assigns(:answers)).to eq(question1.answers.ordered)
      expect(response).to render_template(:question)
    end

    it 'serves a question and shows a time warning if needed' do
      start_time = Time.zone.parse('2024-01-01 12:00:00')
      travel_to start_time + test.time_limit_minutes.minutes - 1.minute do
        test_attempt.update(started_at: start_time)
        get question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0)

        expect(response).to have_http_status(:ok)
        expect(flash[:warning]).to eq(I18n.t('tests.time_warning', minutes: 5))
      end
    end

    it 'accepts an answer and advances to the next question' do
      post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0), params: { answer_id: 123 }

      expect(response).to redirect_to(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 1))
      expect(question_response1.reload.selected_answer_ids).to eq([123])
      expect(flash[:notice]).to eq(I18n.t('tests.answer_saved'))
    end

    it 'accepts an answer and marks the question for later' do
      post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0), params: { marked_for_later: true }

      expect(response).to redirect_to(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 1))
      expect(question_response1.reload.marked_for_later).to be(true)
      expect(question_response1.reload.selected_answer_ids).to be_empty
    end

    it 'rejects an answer and returns to the current question if the answer is invalid' do
      post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0), params: { answer_id: nil }

      expect(response).to redirect_to(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0))
      expect(flash[:alert]).to include('Validation failed')
    end

    it 'rejects ans answer and redirects to results if the test attempt is expired' do
      test_attempt.update(started_at: 1.hour.ago)
      post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0), params: { answer_id: 123 }

      expect(response).to redirect_to(results_theoretical_test_path(test, attempt: test_attempt.access_code))
      expect(flash[:alert]).to eq(I18n.t('tests.time_expired'))
    end

    it 'renders results' do
      get results_theoretical_test_path(test, attempt: test_attempt.access_code)

      expect(assigns(:question_responses)).to eq([question_response1, question_response2])
      expect(assigns(:questions)).to eq([question1, question2])
      expect(response).to render_template(:results)
    end

    it 'renders results and does not show detailed responses if the test attempt is older than 30 days' do
      test_attempt.update(started_at: 32.days.ago, completed_at: 31.days.ago)
      get results_theoretical_test_path(test, attempt: test_attempt.access_code)

      expect(assigns(:question_responses)).to be_empty
      expect(assigns(:questions)).to be_empty
      expect(response).to render_template(:results)
    end

    it 'renders results and redirects to the next question if the test attempt is in progress and not all questions are answered' do
      test_attempt.update(started_at: Time.current)
      post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0), params: { answer_id: 123 }
      get results_theoretical_test_path(test, attempt: test_attempt.access_code)

      expect(response).to redirect_to(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 1))
      expect(flash[:alert]).to eq(I18n.t('tests.answer_all_questions'))
    end

    it 'renders results and completes the test attempt if the test attempt is in progress and all questions are answered' do
      test_attempt.update(started_at: Time.current)
      post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0), params: { answer_id: 123 }
      post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 1), params: { answer_id: 123 }
      get results_theoretical_test_path(test, attempt: test_attempt.access_code)

      expect(test_attempt.reload.completed_at).to be_present
      expect(response).to render_template(:results)
    end
  end

  it 'rejects an answer and returns not found if the question missing' do
    post answer_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0), params: { answer_id: nil }

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects ans answer and redirects to root if test attempt is not found' do
    post answer_theoretical_test_path(test, attempt: 'invalid', question_index: 0), params: { answer_id: 123 }

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq(I18n.t('tests.test_not_found'))
  end
end
