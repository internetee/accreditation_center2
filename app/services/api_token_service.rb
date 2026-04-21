# frozen_string_literal: true

# Service for generating API authentication tokens
class ApiTokenService
  # Token generation methods
  HMAC_METHOD = 'hmac'
  BASE64_METHOD = 'base64'
  SIMPLE_METHOD = 'simple'

  def initialize(username:, password:)
    @username = username
    @password = password
  end

  def generate
    case token_method
    when HMAC_METHOD
      generate_hmac_token
    when BASE64_METHOD
      generate_base64_token
    when SIMPLE_METHOD
      generate_simple_token
    else
      generate_base64_token # Default fallback
    end
  end

  private

  def token_method
    ENV['API_TOKEN_METHOD'] || BASE64_METHOD
  end

  def generate_hmac_token
    secret_key = ENV['API_SECRET_KEY'] || 'default_secret_key'
    timestamp = Time.current.to_i
    token_data = "#{@username}:#{@password}:#{timestamp}"
    OpenSSL::HMAC.hexdigest('SHA256', secret_key, token_data)
  end

  def generate_base64_token
    token_data = "#{@username}:#{@password}"
    Base64.strict_encode64(token_data)
  end

  def generate_simple_token
    timestamp = Time.current.to_i
    "#{@username}:#{@password}:#{timestamp}"
  end
end
