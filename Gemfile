source 'https://rubygems.org'

gem 'action_policy'
gem 'bootsnap', require: false
gem 'coderay', '~> 1.1', '>= 1.1.2'
gem 'dartsass-rails', '~> 0.5.1'
gem 'devise'
gem 'faker'
gem 'faraday'
gem 'figaro'
gem 'font-awesome-sass', '~> 5.15.1'
gem 'friendly_id', '~> 5.6.0'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'
# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem 'kamal', require: false
gem 'kramdown'
gem 'mustache', '~> 1.0'
gem 'omniauth', '>=2.0.0'
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection'
gem 'pagy', '~> 9.3' # omit patch digit
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.6'
gem 'positioning'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 8.1.3'
gem 'ransack'
gem 'simpleidn'
# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# gem 'surveyor', path: 'vendor/gems/surveyor'
# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem 'thruster', require: false
gem 'traco'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem 'bcrypt', '~> 3.1.7'
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem 'image_processing', '~> 1.2'

group :development, :test do
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman', require: false

  gem 'bundler-audit'

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  gem 'factory_bot_rails'

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  # gem 'rubocop-rails-omakase', require: false

  gem 'rspec-rails', '~> 8.0.0'
end

group :development do
  gem 'listen'
  gem 'rails-ai-context'

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'

  # Code coverage
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false

  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'webmock'
end
