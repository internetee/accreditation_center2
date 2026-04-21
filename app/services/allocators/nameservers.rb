# app/services/allocators/nameservers.rb
require 'faker'

module Allocators
  # Generates randomized nameserver hostnames and exports them into attempt vars.
  #
  # Config example (in practical task `vconf.allocators`):
  # { "name": "nameservers", "config": { "count": 2, "export": { "d1_prefix": "ns1_", "d2_prefix": "ns2_" } } }
  # This will export vars: ns1_1, ns1_2, ns2_1, ns2_2
  class Nameservers
    DEFAULT_COUNT = 2

    def initialize(config:, attempt:)
      @cfg = config || {}
      @attempt = attempt
    end

    def call
      export = @cfg['export'] || {}
      d1_prefix = (export['d1_prefix'] || 'ns1_').to_s
      d2_prefix = (export['d2_prefix'] || 'ns2_').to_s
      count = (@cfg['count'] || DEFAULT_COUNT).to_i
      count = DEFAULT_COUNT if count <= 0

      # idempotent-ish: if first pair exists, assume done
      return if @attempt.vars["#{d1_prefix}1"].present? && @attempt.vars["#{d2_prefix}1"].present?

      use_faker = !!@cfg['use_faker']
      if use_faker && defined?(Faker)
        d1_suffix = Faker::Internet.domain_name.downcase
        d2_suffix = Faker::Internet.domain_name.downcase
      else
        # deterministic, readable fallbacks when Faker usage is disabled
        d1_suffix = 'example.net'
        d2_suffix = 'example.org'
      end

      1.upto(count) do |i|
        @attempt.merge_vars!("#{d1_prefix}#{i}" => generate_ns(d1_suffix))
        @attempt.merge_vars!("#{d2_prefix}#{i}" => generate_ns(d2_suffix))
      end
    end

    private

    def generate_ns(suffix)
      "ns#{rand(1..5)}.#{suffix}"
    end
  end
end
