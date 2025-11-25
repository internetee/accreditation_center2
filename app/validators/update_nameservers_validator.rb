# app/validators/update_nameservers_validator.rb
class UpdateNameserversValidator < BaseTaskValidator
  # Config:
  # {
  #   "nameservers": {
  #     "{{domain1}}": "{{ns1_1}}",
  #     "{{domain2}}": "{{ns2_1}}, {{ns2_2}}"
  #   }
  # }
  #
  # Validates that:
  # - The nameservers are updated for the domains
  #
  # Returns:
  #   passed(bool), score(0..1), evidence(Hash), error(String|nil), api_audit(Array), export_vars(Hash)
  def call
    api = []
    configs = resolved_nameserver_configs
    return failure(api, [nameserver_config_missing_message]) if configs.size < 2

    errors = []
    evidence = {}

    configs.first(2).each do |config|
      info = fetch_domain_info(api, config[:domain])
      if info.blank? || info[:success] == false
        errors << domain_not_found_message(config[:domain])
        next
      end

      actual = extract_nameservers(info)
      if set_matches?(actual, config[:expected])
        evidence[config[:key]] = { name: config[:domain], actual: actual, expected: config[:expected] }
      else
        errors << nameservers_mismatch_message(config[:domain])
      end
    end

    return failure(api, errors) unless errors.empty?

    pass(api, evidence)
  end

  private

  def resolved_nameserver_configs
    ns_cfg = @config['nameservers'] || {}
    ns_cfg.keys.each_with_index.map do |key, index|
      {
        key: :"dom#{index + 1}",
        domain: Mustache.render(key.to_s, @attempt.vars),
        expected: Array(ns_cfg[key].to_s.split(',')).map do |ns|
          normalize_ns(Mustache.render(ns.strip, @attempt.vars))
        end.compact.uniq.sort
      }
    end
  end

  def nameserver_config_missing_message
    I18n.t('validators.update_nameservers_validator.nameservers_config_missing_or_empty')
  end

  def domain_not_found_message(domain)
    I18n.t('validators.update_nameservers_validator.domain_not_found', domain: domain)
  end

  def nameservers_mismatch_message(domain)
    I18n.t('validators.update_nameservers_validator.nameservers_mismatch', domain: domain)
  end

  def fetch_domain_info(api, name)
    with_audit(api, 'domain_info') { @service.domain_info(name: name) }
  end

  def extract_nameservers(info_hash)
    Array(info_hash[:nameservers]).map do |ns|
      if ns.is_a?(Hash)
        normalize_ns(ns[:hostname] || ns[:name])
      else
        normalize_ns(ns)
      end
    end.compact.uniq.sort
  end

  def normalize_ns(value)
    return nil if value.nil?

    value.to_s.strip.downcase.chomp('.')
  end

  def set_matches?(actual, expected)
    actual.sort == expected.sort
  end

  def api_service_adapter
    DomainService.new(token: @token)
  end
end
