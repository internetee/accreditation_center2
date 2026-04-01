# app/services/oidc_authentication_service.rb
# frozen_string_literal: true

class OidcAuthenticationService < ApiConnector
  def initialize(uid:)
    @api_url = ENV.fetch('REPP_BASE_URL') + ENV.fetch('REPP_AUTH_TOKEN_URL')
    @uid = uid.to_s
    raise ArgumentError, 'OIDC uid is required' if @uid.blank?

    ssl_options = {
      verify: Rails.env.production?,
      client_cert_file: ENV['WEBCLIENT_CERT_PATH'],
      client_key_file: ENV['WEBCLIENT_KEY_PATH']
    }
    super(token: 'unused', ssl: ssl_options)
    @headers = {
      'Content-Type' => 'application/json',
      'Requester' => 'webclient'
    }
  end

  def authenticate_user
    body = { auth: { uid: @uid } }.to_json
    result = make_request(:post, @api_url, { headers: @headers, body: body })
    return result unless result[:success]

    payload = normalize_payload(result[:data])
    return error_response(nil, I18n.t('errors.unexpected_response')) unless payload

    success_auth_response(payload)
  rescue ArgumentError => e
    error_response(e.message, I18n.t('errors.invalid_data_format'))
  end

  private

  def normalize_payload(data)
    return nil unless data.is_a?(Hash)
    return nil unless data.key?('id')

    symbolize_keys_deep(data)
  end

  def success_auth_response(data)
    {
      success: true,
      auth_token: data[:token], # registry-issued token
      user_id: data[:id],
      username: data[:username],
      roles: Array(data[:roles]),
      registrar_name: data[:registrar_name],
      registrar_reg_no: data[:registrar_reg_no],
      registrar_email: data[:registrar_email],
      accreditation_date: data[:accreditation_date],
      accreditation_expire_date: data[:accreditation_expire_date]
    }
  end
end
