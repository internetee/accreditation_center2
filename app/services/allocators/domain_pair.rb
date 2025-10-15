# app/services/allocators/domain_pair.rb
require 'simpleidn'
require 'faker'

module Allocators
  class DomainPair
    DEFAULT_TRIES = 2

    def initialize(config:, attempt:)
      @cfg = config
      @attempt = attempt
      @service = service_adapter(@attempt.user)
    end

    def call
      export = @cfg['export'] || {}
      key1   = export['domain1']       || 'domain1'
      key2   = export['domain2']       || 'domain2'
      key2a  = export['domain2_ascii'] || 'domain2_ascii'

      # idempotent: skip if already present (e.g., re-provision call)
      return if @attempt.vars[key1].present? && @attempt.vars[key2].present?

      use_faker = !!@cfg['use_faker']

      base1 = @cfg['base1'] || default_ascii_label(use_faker)
      base2 = @cfg['base2'] || default_unicode_label(use_faker, base1)
      tld   = @cfg['tld']   || 'ee'
      tries = (@cfg['availability_checks'] || DEFAULT_TRIES).to_i

      tries.times do
        suffix = suffix_for(@attempt) # stable-ish but unique per attempt
        d1 = "#{base1}-#{suffix}.#{tld}"
        d2 = "#{base2}-#{suffix}.#{tld}"
        d2_ascii = SimpleIDN.to_ascii(d2)

        if available?(d1) && available?(d2_ascii)
          @attempt.merge_vars!(key1 => d1, key2 => d2, key2a => d2_ascii)
          return
        end
      end

      raise "Allocator domain_pair: could not find two free domains after #{tries} attempts"
    end

    private

    def suffix_for(attempt)
      # deterministic-ish uniqueness: attempt id + short random
      "#{attempt.id}-#{SecureRandom.alphanumeric(6).downcase}"
    end

    def default_ascii_label(use_faker)
      if use_faker && defined?(Faker)
        label = Faker::Internet.domain_word.to_s.downcase
        label.gsub(/[^a-z0-9-]/, '')[0, 20].presence || 'test'
      else
        'gransytest'
      end
    end

    def default_unicode_label(use_faker, fallback_ascii)
      if use_faker && defined?(Faker)
        ascii = fallback_ascii.presence || default_ascii_label(true)
        to_unicode_variant(ascii)
      else
        'gränsytest'
      end
    end

    def to_unicode_variant(ascii)
      # Replace some vowels/consonants with Estonian diacritics to produce IDN
      map = {
        'a' => %w[ä],
        'o' => %w[ö õ],
        'u' => %w[ü],
        's' => %w[š],
        'z' => %w[ž]
      }
      chars = ascii.chars.map do |ch|
        options = map[ch]
        if options && rand < 0.5
          options.sample
        else
          ch
        end
      end
      result = chars.join
      # ensure at least one unicode char
      if result.ascii_only?
        result = result.sub('a', 'ä').sub('o', 'õ').sub('u', 'ü')
      end
      result
    end

    def available?(fqdn)
      result = @service.domain_info(name: fqdn)
      Rails.logger.info "DomainPair available? result: #{result.inspect}"
      true if result[:success] == false
    end

    def service_adapter(user)
      DomainService.new(username: user.username, password: user.password)
    end
  end
end
