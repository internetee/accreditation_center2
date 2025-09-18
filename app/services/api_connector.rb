# frozen_string_literal: true

# Base class for API services with HTTP client and error handling
class ApiConnector
  # Class-level configuration
  class << self
    attr_accessor :timeout, :max_retries, :retry_delay, :logging
  end

  # Default configuration
  self.timeout = 10
  self.max_retries = 3
  self.retry_delay = 1
  self.logging = Rails.env.development?

  def initialize(username:, password:)
    @auth_token = generate_api_token(username, password)
    @headers = { 'Authorization' => "Basic #{@auth_token}" }
    @connection = build_connection
  end

  # Generic method to make API requests with error handling
  def make_request(method, url, options = {})
    return error_response('API endpoint not configured') unless url

    begin
      response = @connection.send(method) do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'

        # Add custom headers
        options[:headers]&.each { |key, value| req.headers[key] = value }

        # Add body for POST/PUT requests
        req.body = options[:body] if options[:body]
      end

      handle_response(response)
    rescue Faraday::TimeoutError => e
      handle_timeout_error(e)
    rescue Faraday::ConnectionFailed => e
      handle_connection_error(e)
    rescue Faraday::Error => e
      handle_faraday_error(e)
    rescue StandardError => e
      handle_generic_error(e)
    end
  end

  def handle_response(response)
    case response.status
    when 200
      success_response(response.body)
    when 401
      error_response('Invalid credentials')
    when 403
      error_response('Access denied')
    when 404
      error_response(response.body['errors'] || 'Service not found')
    when 422
      error_response('Invalid data')
    when 500..599
      error_response(response.body['errors'] || 'Service error')
    else
      error_response('Unexpected response from service')
    end
  end

  private

  def build_connection
    Faraday.new do |faraday|
      faraday.request :url_encoded
      faraday.request :json
      faraday.response :json
      faraday.adapter Faraday.default_adapter

      # Configure timeout
      faraday.options.timeout = self.class.timeout
      faraday.options.open_timeout = self.class.timeout

      # Configure logging if enabled
      if self.class.logging
        faraday.response :logger, Rails.logger, { headers: false, bodies: false }
      end
    end
  end

  def generate_api_token(username, password)
    # Generate a token based on username and password
    # You can customize this method based on your API requirements

    # Get token generation method from configuration
    token_method = ENV['API_TOKEN_METHOD'] || 'base64'

    case token_method
    when 'hmac'
      generate_hmac_token(username, password)
    when 'base64'
      generate_base64_token(username, password)
    when 'simple'
      generate_simple_token(username, password)
    else
      generate_base64_token(username, password) # Default to base64
    end
  end

  def generate_hmac_token(username, password)
    # Using HMAC for secure token generation
    secret_key = ENV['API_SECRET_KEY'] || 'default_secret_key'
    timestamp = Time.current.to_i
    token_data = "#{username}:#{password}:#{timestamp}"
    OpenSSL::HMAC.hexdigest('SHA256', secret_key, token_data)
  end

  def generate_base64_token(username, password)
    # Base64 encoded token
    token_data = "#{username}:#{password}"
    Base64.strict_encode64(token_data)
  end

  def generate_simple_token(username, password)
    # Simple concatenation (less secure, but simple)
    timestamp = Time.current.to_i
    "#{username}:#{password}:#{timestamp}"
  end

  def handle_timeout_error(error)
    Rails.logger.error "API Connector timeout: #{error.message}" if self.class.logging
    error_response('Service timeout')
  end

  def handle_connection_error(error)
    Rails.logger.error "API Connector connection failed: #{error.message}" if self.class.logging
    error_response('Cannot connect to service')
  end

  def handle_faraday_error(error)
    Rails.logger.error "API Connector Faraday error: #{error.message}" if self.class.logging
    error_response('Network error')
  end

  def handle_generic_error(error)
    Rails.logger.error "API Connector error: #{error.message}"
    error_response('Service temporarily unavailable')
  end

  def success_response(data)
    {
      success: true,
      data: data,
      message: 'Operation successful'
    }
  end

  def error_response(message)
    {
      success: false,
      message: message,
      data: nil
    }
  end
end
