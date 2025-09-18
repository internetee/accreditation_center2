# frozen_string_literal: true

# Service for retrieving contact data from the registry API.
# Builds authorization headers using provided credentials and
# exposes a simple `contact_info(id:)` method returning a symbolized hash.
class ContactService < ApiConnector
  def initialize(username:, password:)
    @api_url = ENV['BASE_URL'] + ENV['GET_CONTACT']
    super(username: username, password: password)
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
    data = JSON.parse(data) if data.is_a?(String)
    symbolize_keys_deep(data['contact'])
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
