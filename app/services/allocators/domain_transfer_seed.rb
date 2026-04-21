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
  #   "count": 1,
  #   "auto_transfer_code": true,
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
      auto_transfer_code = @cfg['auto_transfer_code'] == true || false
      manual_transfer_code = SecureRandom.hex(8)

      # idempotency: if first keys exist, assume already provisioned
      return if @attempt.vars[domain_key].present? && @attempt.vars[code_key].present?

      use_faker = !!@cfg['use_faker']
      base = @cfg['base'] || default_label(use_faker)
      tld  = @cfg['tld']  || 'ee'
      count = (@cfg['count'] || 1).to_i
      count = 1 if count <= 0

      registrant = ENV['ACCR_BOT_CONTACT_CODE']
      raise 'Allocator domain_transfer_seed: missing bot contact code' if registrant.blank?

      service = ReppDomainService.new

      1.upto(count) do |i|
        fqdn = "#{base}-#{@attempt.id}-#{i}-#{SecureRandom.hex(3)}.#{tld}"

        payload = {
          name: fqdn,
          registrant: registrant,
          transfer_code: auto_transfer_code ? nil : manual_transfer_code,
          period: 1,
          period_unit: 'y',
          admin_contacts: [registrant]
        }

        res = service.create_domain(payload)
        if res[:success] == false
          raise "Allocator domain_transfer_seed: create failed #{res[:errors] || res}"
        end

        domain_name = res.dig(:domain, :name) || fqdn
        transfer_code = res.dig(:domain, :transfer_code)
        raise "Allocator domain_transfer_seed: transfer_code not found #{res.inspect}" if transfer_code.blank?

        # Export numbered keys
        @attempt.merge_vars!("#{domain_key}#{i}" => domain_name, "#{code_key}#{i}" => transfer_code)
        # Also export base keys for the first item for backward compatibility
        if i == 1
          @attempt.merge_vars!(domain_key => domain_name, code_key => transfer_code)
        end
      end
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
