Rails.application.config.to_prepare do
  VoogFooter.configure do |config|
    config.site_url = ENV.fetch('voog_site_url', 'https://www.internet.ee').presence
    config.api_key = ENV.fetch('voog_api_key', '').presence
    config.enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch('voog_site_fetching_enabled', 'false'))
    config.cache_ttl = ENV.fetch('voog_footer_cache_ttl', '3600').to_i
    config.ssl_verify = if ENV.fetch('voog_ssl_verify', nil).present?
                          ActiveModel::Type::Boolean.new.cast(ENV.fetch('voog_ssl_verify', nil))
                        else
                          Rails.env.production? || Rails.env.staging?
                        end
    config.cache_store = Rails.cache
    config.locales = %w[en et]
  end
end
