# app/services/allocators/domain_pair.rb
require 'simpleidn'
require 'faker'

module Allocators
  # Allocates a pair of domains for practical testing: one ASCII and one IDN with Estonian diacritics
  #
  # Config:
  # {
  #   "use_faker": true
  # }
  class DomainPair
    DEFAULT_TRIES = 2

    # Estonian diacritics for IDN generation
    VOWEL_DIACRITICS = {
      'a' => %w[ä],
      'o' => %w[ö õ],
      'u' => %w[ü]
    }.freeze

    CONSONANT_DIACRITICS = {
      's' => %w[š],
      'z' => %w[ž]
    }.freeze

    # Probability thresholds for character replacement
    VOWEL_REPLACEMENT_PROBABILITY = 0.7
    CONSONANT_REPLACEMENT_PROBABILITY = 0.3

    # Fallback vowel replacements when no diacritics applied
    FALLBACK_VOWELS = %w[a o u].freeze
    FALLBACK_REPLACEMENTS = { 'a' => 'ä', 'o' => 'õ', 'u' => 'ü' }.freeze

    def initialize(config:, attempt:)
      @cfg = config
      @attempt = attempt
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

      suffix = suffix_for(@attempt) # stable-ish but unique per attempt
      d1 = "#{base1}-#{suffix}.#{tld}"
      d2 = "#{base2}-#{suffix}.#{tld}"
      d2_ascii = SimpleIDN.to_ascii(d2)

      @attempt.merge_vars!(key1 => d1, key2 => d2, key2a => d2_ascii)
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
      result = apply_diacritics(ascii)
      ensure_idn_conversion(result)
    end

    def apply_diacritics(ascii)
      ascii.chars.map do |char|
        if should_replace_vowel?(char)
          VOWEL_DIACRITICS[char].sample
        elsif should_replace_consonant?(char)
          CONSONANT_DIACRITICS[char].sample
        else
          char
        end
      end.join
    end

    def should_replace_vowel?(char)
      VOWEL_DIACRITICS.key?(char) && rand < VOWEL_REPLACEMENT_PROBABILITY
    end

    def should_replace_consonant?(char)
      CONSONANT_DIACRITICS.key?(char) && rand < CONSONANT_REPLACEMENT_PROBABILITY
    end

    def ensure_idn_conversion(result)
      # if the result is already ASCII-only, return it
      return result unless result.ascii_only?

      result = apply_fallback_replacements(result)
      result += 'ä' if result.ascii_only?
      result
    end

    def apply_fallback_replacements(result)
      FALLBACK_VOWELS.each do |vowel|
        if result.include?(vowel)
          return result.sub(vowel, FALLBACK_REPLACEMENTS[vowel])
        end
      end
      result
    end
  end
end
