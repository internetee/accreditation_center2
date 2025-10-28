# frozen_string_literal: true

# Base service for bot authentication with SSL certificates
# Provides common SSL configuration for accr_bot operations
class BotAuthService < ApiConnector
  def initialize
    @username = ENV['ACCR_BOT_USERNAME']
    @password = ENV['ACCR_BOT_PASSWORD']

    raise 'Bot credentials not configured' if @username.blank? || @password.blank?

    ssl_options = {
      verify: true,
      client_cert_file: ENV['CLIENT_BOT_CERTS_PATH'],
      client_key_file: ENV['CLIENT_BOT_KEY_PATH']
    }

    super(username: @username, password: @password, ssl: ssl_options)
  end

  # Get bot contact code for domain operations
  def bot_contact_code
    ENV['ACCR_BOT_CONTACT_CODE']
  end

  # Get bot registrar name
  def bot_registrar_name
    ENV['ACCR_BOT_REGISTRAR_NAME']
  end
end
