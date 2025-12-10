require 'rails_helper'

RSpec.describe 'Admin login', type: :system do
  before { driven_by(:rack_test) }

  it 'logs in as admin' do
    admin = create(:user, :admin)

    visit login_path
    fill_in 'Username', with: admin.username
    fill_in 'Password', with: admin.password
    click_button 'Sign in'

    expect(page).to have_current_path(admin_dashboard_path(locale: 'en'))
    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
  end
end
