require 'rails_helper'

RSpec.describe 'Registrar completes theoretical test', type: :system do
  before { driven_by(:rack_test) }

  it 'logs in via API and completes a theoretical test' do
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

    test_category = create(:test_category, questions_per_category: 2, active: true)
    question1 = create(:question, test_category: test_category, display_order: 1, active: true)
    question2 = create(:question, test_category: test_category, display_order: 2, active: true)
    
    answer1_correct = create(:answer, :correct, question: question1, display_order: 1)
    create(:answer, question: question1, display_order: 2)
    create(:answer, question: question1, display_order: 3)
    
    answer2_correct = create(:answer, :correct, question: question2, display_order: 1)
    create(:answer, question: question2, display_order: 2)
    
    test = create(:test, :theoretical, active: true)
    test.test_categories << test_category

    visit login_path
    fill_in 'Username', with: 'registrar1'
    fill_in 'Password', with: 'Secret123'
    click_button 'Sign in'

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    expect(page).to have_content('Welcome back, user1!')

    user = User.find_by(username: 'user1')
    test_attempt = Attempts::Assign.call!(user: user, test: test)

    visit root_path(locale: 'en')
    within(:xpath, "//tr[contains(., '#{test.title}')]") do
      click_button I18n.t('home.index.start_test')
    end
    expect(page).to have_current_path(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: 0, locale: 'en'))

    test_attempt.reload
    questions = test_attempt.questions
    
    questions.each_with_index do |question, index|
      expect(page).to have_content(question.text)
      
      correct_answer = question.answers.find_by(correct: true)
      choose "answer_#{correct_answer.id}"
      
      click_button I18n.t('tests.save_answer')
      
      if index < questions.count - 1
        expect(page).to have_current_path(question_theoretical_test_path(test, attempt: test_attempt.access_code, question_index: index + 1, locale: 'en'))
      end
    end

    test_attempt.reload
    expect(test_attempt.all_questions_answered?).to be true

    visit results_theoretical_test_path(test, attempt: test_attempt.access_code, locale: 'en')
    
    test_attempt.reload
    expect(test_attempt.completed?).to be true
    expect(page).to have_content(I18n.t('tests.results.title'))
  end
end
