# frozen_string_literal: true

# Service for handling user authentication via external API
class AuthenticationService < ApiConnector
  def initialize
    # Use authentication-specific API URL
    @api_url = ENV['BASE_URL'] + ENV['AUTH_API_URL']
    super
  end

  # Authenticate user via API using GET request
  def authenticate_user(username, password)
    # Generate API token from username and password
    api_token = generate_api_token(username, password)
    headers = { 'Authorization' => "Basic #{api_token}" }

    # Use base class make_request method with error handling
    result = make_request(:get, @api_url, { headers: headers })

    # Handle authentication-specific response processing
    if result[:success]
      handle_auth_success(result[:data])
    else
      result
    end
  end

  private

  def handle_auth_success(data)
    # Check if the response has the expected structure
    if data.is_a?(Hash) && data['code'] == 1000
      success_auth_response(data['data'])
    else
      # If not the expected structure, treat as direct data
      success_auth_response(data)
    end
  end

  def success_auth_response(data)
    {
      success: true,
      user_id: data['id'],
      username: data['username'],
      roles: data['roles'],
      uuid: data['uuid'],
      registrar_name: data['registrar_name'],
      registrar_reg_no: data['registrar_reg_no'],
      registrar_email: data['registrar_email'],
    }
  end
end
