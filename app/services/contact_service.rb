# frozen_string_literal: true

# Service for retrieving contact data from the registry API.
# Builds authorization headers using provided credentials and
# exposes a simple `contact_info(id:)` method returning a symbolized hash.
class ContactService < ApiConnector
  def initialize(token:)
    @api_url = ENV['BASE_URL'] + ENV['GET_CONTACT']
    super(token: token)
  end

  def contact_info(id:)
    result = make_request(:get, "#{@api_url}?id=#{id}", { headers: @headers })

    if result[:success]
      handle_auth_success(result[:data])
    else
      result
    end
  end

  private

  def handle_auth_success(data)
    data = parse_json(data)

    if data.is_a?(Hash) && data.key?('contact')
      symbolize_keys_deep(data['contact'])
    else
      error_response(nil, I18n.t('errors.unexpected_response'))
    end
  end
end
