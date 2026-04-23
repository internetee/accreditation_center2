# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # DELETE /resource/sign_out
  def destroy
    session[:auth_token] = nil
    session[:completed_attempt_review_access] = nil
    super
  end
end
