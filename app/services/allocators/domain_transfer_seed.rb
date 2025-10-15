# app/services/allocators/domain_transfer_seed.rb
require 'faker'

module Allocators
  # Creates a domain under a bot user (accr_bot) and exports its name and transfer code
  # into attempt vars for a later transfer task.
  #
  # Config:
  # {
  #   "use_faker": true,
  #   "tld": "ee",
  #   "export": { "domain_key": "xfer_domain", "code_key": "xfer_code" },
  # }
  class DomainTransferSeed
    def initialize(config:, attempt:)
      @cfg = config || {}
      @attempt = attempt
    end

    def call
      export = @cfg['export'] || {}
      domain_key = (export['domain_key'] || 'xfer_domain').to_s
      code_key   = (export['code_key']   || 'xfer_code').to_s

      return if @attempt.vars[domain_key].present? && @attempt.vars[code_key].present?

      use_faker = !!@cfg['use_faker']
      base = @cfg['base'] || default_label(use_faker)
      tld  = @cfg['tld']  || 'ee'
      fqdn = "#{base}-#{@attempt.id}-#{SecureRandom.hex(3)}.#{tld}"

      bot_user = ENV['ACCR_BOT_USERNAME']
      bot_pass = ENV['ACCR_BOT_PASSWORD']
      registrant = ENV['ACCR_BOT_CONTACT_CODE']
      raise 'Allocator domain_transfer_seed: missing bot credentials' if bot_user.blank? || bot_pass.blank?

      ssl_opts = { verify: true, client_cert_file: ENV['CLIENT_BOT_CERTS_PATH'], client_key_file: ENV['CLIENT_BOT_KEY_PATH'] }.symbolize_keys
      repp = ReppDomainService.new(username: bot_user, password: bot_pass, ssl: ssl_opts)

      payload = {
        name: fqdn,
        registrant: registrant,
        period: 1,
        period_unit: 'y',
        admin_contacts: [registrant]
      }

      res = repp.create_domain(payload)

      if res[:success] == false
        raise "Allocator domain_transfer_seed: create failed #{res[:errors] || res}"
      end

      domain_name = res.dig(:domain, :name) || fqdn
      transfer_code = res.dig(:domain, :transfer_code)

      raise "Allocator domain_transfer_seed: transfer_code not found #{res.inspect}" if transfer_code.blank?

      @attempt.merge_vars!(domain_key => domain_name, code_key => transfer_code)
    end

    private

    def default_label(use_faker)
      if use_faker && defined?(Faker)
        label = Faker::Internet.domain_word.to_s.downcase
        label.gsub(/[^a-z0-9-]/, '')[0, 20].presence || 'seed'
      else
        'seed'
      end
    end
  end
end
