# require 'rails_helper'

# RSpec.describe 'User flows', type: :system do
#   before { driven_by(:rack_test) }

#   it 'logs in via API and completes a theoretical test' do
#     allow(AuthenticationService).to receive(:new).and_return(double(authenticate_user: {
#       success: true, username: 'registrar1', registrar_email: 'r@example.com',
#       registrar_name: 'Registrar Ltd', accreditation_date: Date.current,
#       accreditation_expire_date: 1.year.from_now.to_date
#     }))
#     allow(ApiTokenService).to receive(:new).and_return(double(generate: 'jwt-token'))

#     visit login_path
#     fill_in 'Username', with: 'registrar1'
#     fill_in 'Password', with: 'Secret123'
#     click_button 'Log in'

#     expect(page).to have_content(I18n.t('devise.sessions.signed_in'))

#     # Navigate test flow (adapt selectors to your views)
#     click_link 'Start theoretical test'
#     expect(page).to have_content('Question')
#     choose(option: true) rescue nil
#     click_button 'Next'
#     # ...
#     expect(page).to have_content('Results')
#   end
# end
