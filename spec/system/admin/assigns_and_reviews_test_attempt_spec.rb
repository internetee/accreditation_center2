require 'rails_helper'

RSpec.describe 'Admin assigns and reviews test attempt', type: :system do
  before { driven_by(:rack_test) }

  it 'allows admin to assign test to user, user completes it, and admin views detailed results' do
    admin = create(:user, :admin)
    regular_user = create(:user, username: 'testuser', email: 'testuser@example.com')

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
    fill_in 'Username', with: admin.username
    fill_in 'Password', with: admin.password
    click_button 'Sign in'

    expect(page).to have_current_path(admin_dashboard_path(locale: 'en'))

    visit admin_test_path(test, locale: 'en')
    click_link I18n.t(:assign)

    expect(page).to have_current_path(new_admin_test_test_attempt_path(test, locale: 'en'))
    
    select "#{regular_user.username} (#{regular_user.email})", from: 'test_attempt[user_id]'
    click_button I18n.t('admin.test_attempts.form.assign_test')

    expect(page).to have_content(I18n.t('admin.test_attempts.assigned'))
    
    test_attempt = TestAttempt.find_by(user: regular_user, test: test)
    expect(test_attempt).to be_present

    visit logout_path(locale: 'en')

    allow(AuthenticationService).to receive(:new).and_return(
      double(
        authenticate_user: {
          success: true, username: regular_user.username, registrar_email: regular_user.email,
          registrar_name: 'Test Registrar', accreditation_date: Date.current,
          accreditation_expire_date: 1.year.from_now.to_date
        }
      )
    )
    allow(ApiTokenService).to receive(:new).and_return(double(generate: 'jwt-token'))

    visit login_path
    fill_in 'Username', with: regular_user.username
    fill_in 'Password', with: regular_user.password
    click_button 'Sign in'

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))

    visit root_path(locale: 'en')
    within(:xpath, "//tr[contains(., '#{test.title}')]") do
      click_button I18n.t('home.index.start_test')
    end

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

    visit logout_path(locale: 'en')

    visit login_path
    fill_in 'Username', with: admin.username
    fill_in 'Password', with: admin.password
    click_button 'Sign in'

    visit admin_test_test_attempt_path(test, test_attempt, locale: 'en')
    
    expect(page).to have_content(regular_user.username)
    expect(page).to have_content(test.title)
    expect(page).to have_content(I18n.t('admin.test_attempts.show.question_responses', default: 'Question responses'))
    
    test_attempt.reload
    expect(test_attempt.question_responses.count).to eq(questions.count)
  end
end
