require 'rails_helper'

RSpec.describe 'Registrar completes practical test', type: :system do
  before { driven_by(:rack_test) }

  it 'allows user to start and complete a practical test flow' do
    allow(AuthenticationService).to receive(:new).and_return(
      double(
        authenticate_user: {
          success: true, username: 'user1', registrar_email: 'r@example.com',
          registrar_name: 'Registrar Ltd', accreditation_date: Date.current,
          accreditation_expire_date: 1.year.from_now.to_date
        }
      )
    )
    allow(ApiTokenService).to receive(:new).and_return(double(generate: 'jwt-token'))

    test = create(:test, :practical, active: true)
    
    practical_task = create(:practical_task,
      test: test,
      title_et: 'Test ülesanne',
      title_en: 'Test task',
      body_et: 'Sisesta kontakt ID: {{contact_id}}',
      body_en: 'Enter contact ID: {{contact_id}}',
      validator: {
        klass: 'CreateContactsValidator',
        config: {},
        input_fields: [
          {
            name: 'contact_id',
            label_et: 'Kontakti ID',
            label_en: 'Contact ID',
            required: true
          }
        ],
        depends_on_task_ids: []
      },
      display_order: 1,
      active: true
    )

    visit login_path
    fill_in 'Username', with: 'user1'
    fill_in 'Password', with: 'anything'
    click_button 'Sign in'

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    expect(page).to have_content('Welcome back, user1!')

    user = User.find_by(username: 'user1')
    test_attempt = Attempts::Assign.call!(user: user, test: test)

    visit root_path(locale: 'en')
    within(:xpath, "//tr[contains(., '#{test.title}')]") do
      click_button I18n.t('home.index.start_test')
    end

    expect(page).to have_current_path(question_practical_test_path(test, attempt: test_attempt.access_code, question_index: 0, locale: 'en'))

    test_attempt.reload
    tasks = test.practical_tasks.active.ordered

    mock_validator_result = {
      passed: true,
      score: 1.0,
      evidence: { contact: { id: '12345' } },
      errors: nil,
      api_audit: [],
      export_vars: { 'contact_id' => '12345' }
    }

    tasks.each_with_index do |task, index|
      expect(page).to have_content('Contact ID')

      validator_class_name = task.klass_name
      validator_class = validator_class_name.to_s.safe_constantize
      
      if validator_class
        validator_instance = double(call: mock_validator_result)
        allow(validator_class).to receive(:new).and_return(validator_instance)
      end

      fill_in 'inputs[contact_id]', with: '12345'
      click_button I18n.t('validate')

      test_attempt.reload
      result = test_attempt.practical_task_results.find_by(practical_task: task)
      expect(result).to be_present
      expect(result.status).to eq('passed')

      if index < tasks.count - 1
        expect(page).to have_current_path(question_practical_test_path(test, attempt: test_attempt.access_code, question_index: index + 1, locale: 'en'))
      end
    end

    test_attempt.reload
    expect(test_attempt.all_tasks_completed?).to be true

    visit results_practical_test_path(test, attempt: test_attempt.access_code, locale: 'en')

    test_attempt.reload
    expect(test_attempt.completed?).to be true
    expect(page).to have_content(I18n.t('tests.results.title'))
  end
end
