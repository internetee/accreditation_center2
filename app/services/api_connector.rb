# frozen_string_literal: true

# Base class for API services with HTTP client and error handling
require 'openssl'
class ApiConnector
  # Default configuration
  TIMEOUT = 10

  def initialize(username: nil, password: nil, token: nil, ssl: {})
    @auth_token = token || ApiTokenService.new(username: username, password: password).generate
    @headers = { 'Authorization' => "Basic #{@auth_token}" }
    @ssl_opts = ssl || {}
    @connection = build_connection
  end

  # Generic method to make API requests with error handling
  def make_request(method, url, options = {})
    return error_response('API endpoint not configured') unless url

    Rails.logger.debug("Making #{method} request to #{url} with options: #{options}")

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
    ensure
      Rails.logger.debug("Response: #{response.inspect}")
    end
  end

  def handle_response(response)
    case response.status
    when 200
      success_response(response.body)
    when 401
      error_response('Invalid credentials')
    when 403
      error_response(response.body['errors'] || 'Access denied')
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
      faraday.options.timeout = TIMEOUT
      faraday.options.open_timeout = TIMEOUT

      # Configure logging if enabled
      if ENV['RAILS_LOG_LEVEL'] == 'debug'
        faraday.response :logger, nil, {
          headers: false,
          bodies: true,
          errors: true,
          log_level: :debug
        }
      end

      # SSL configuration (optional; services not needing SSL can skip)
      ssl_verify = if @ssl_opts.key?(:verify)
                     !!@ssl_opts[:verify]
                   else
                     false
                   end
      faraday.ssl.verify = ssl_verify

      ca_file = @ssl_opts[:ca_file].presence
      faraday.ssl.ca_file = ca_file if ca_file.present?

      cert_file = @ssl_opts[:client_cert_file].presence
      key_file  = @ssl_opts[:client_key_file].presence

      if cert_file.present? && key_file.present? && File.exist?(cert_file) && File.exist?(key_file)
        faraday.ssl.client_cert = OpenSSL::X509::Certificate.new(File.read(cert_file))
        faraday.ssl.client_key  = OpenSSL::PKey.read(File.read(key_file))
      end
    end
  end

  def handle_timeout_error(error)
    Rails.logger.error "API Connector timeout: #{error.message}"
    error_response('Service timeout')
  end

  def handle_connection_error(error)
    Rails.logger.error "API Connector connection failed: #{error.message}"
    error_response('Cannot connect to service')
  end

  def handle_faraday_error(error)
    Rails.logger.error "API Connector Faraday error: #{error.message}"
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

  def symbolize_keys_deep(obj)
    case obj
    when Array
      obj.map { |e| symbolize_keys_deep(e) }
    when Hash
      obj.each_with_object({}) do |(k, v), h|
        h[k.to_sym] = symbolize_keys_deep(v)
      end
    else
      obj
    end
  end
end
