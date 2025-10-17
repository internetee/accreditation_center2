# frozen_string_literal: true

# Service for retrieving domain data from the registry API.
# Exposes `domain_info(name:)` returning a symbolized hash on success
# and raising on API errors (allocator rescues and treats as unavailable).
class DomainService < ApiConnector
  def initialize(token:)
    @api_url_info = ENV['BASE_URL'] + ENV['GET_DOMAIN_INFO']
    super(token: token)
  end

  def domain_info(name:)
    url = "#{@api_url_info}?name=#{CGI.escape(name.to_s)}"
    result = make_request(:get, url, { headers: @headers })

    return result unless result[:success]

    data = result[:data]
    data = JSON.parse(data) if data.is_a?(String)

    payload = if data.is_a?(Hash) && data.key?('domain')
                data['domain']
              else
                data
              end

    symbolize_keys_deep(payload)
  end
end
