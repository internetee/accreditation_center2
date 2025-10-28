# frozen_string_literal: true

# Client for REPP domain operations needed for seeding transfer tasks
class ReppDomainService < BotAuthService
  def initialize
    @api_url_create = ENV['REPP_BASE_URL'].to_s + ENV['REPP_CREATE_DOMAIN'].to_s
    super()
  end

  # params example:
  # {
  #   name: "example.ee",
  #   registrant: "ORG123",
  #   period: 1,
  #   period_unit: "y"
  # }
  def create_domain(params)
    body = { domain: params }.to_json
    result = make_request(:post, @api_url_create, { headers: @headers, body: body })

    return result unless result[:success]

    data = result[:data]
    data = JSON.parse(data) if data.is_a?(String)
    payload = data.is_a?(Hash) && data.key?('data') ? data['data'] : data
    symbolize_keys_deep(payload)
  end
end
