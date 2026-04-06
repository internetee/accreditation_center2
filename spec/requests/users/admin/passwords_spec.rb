require 'rails_helper'

RSpec.describe 'Users::Admin::Passwords', type: :request do
  describe 'POST /admin/password' do
    it 'sends reset instructions for admin email' do
      admin = create(:user, :admin, password: 'AdminPass123!', password_confirmation: 'AdminPass123!')

      post admin_password_path, params: { user: { email: admin.email } }

      expect(response).to redirect_to(new_admin_session_path)
      expect(flash[:notice]).to eq(I18n.t('devise.passwords.send_instructions'))
      expect(admin.reload.reset_password_token).to be_present
    end

    it 'rejects unknown email' do
      post admin_password_path, params: { user: { email: 'missing@example.test' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t('devise.failure.not_found_in_database', authentication_keys: 'email'))
    end
  end

  describe 'PATCH /admin/password' do
    it 'shows localized invalid token error' do
      patch admin_password_path, params: {
        user: {
          reset_password_token: 'invalid-token',
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t('devise.passwords.invalid_token'))
    end

    it 'validates password confirmation mismatch' do
      admin = create(:user, :admin, password: 'AdminPass123!', password_confirmation: 'AdminPass123!')
      raw_token = admin.send_reset_password_instructions

      patch admin_password_path, params: {
        user: {
          reset_password_token: raw_token,
          password: 'NewPass123!',
          password_confirmation: 'DifferentPass123!'
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      localized_fragment = I18n.t('errors.messages.confirmation', attribute: User.human_attribute_name(:password))
      expect(flash[:alert]).to match(/#{Regexp.escape(localized_fragment)}|Password confirmation doesn'?t match Password/)
    end
  end
end
