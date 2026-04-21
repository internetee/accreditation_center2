# app/controllers/concerns/localization.rb
module Localization
  extend ActiveSupport::Concern

  included do
    before_action :switch_locale
  end

  private

  def switch_locale
    I18n.locale = extract_locale || I18n.default_locale
    @pagy_locale = I18n.locale.to_s
  end

  def extract_locale
    set_locale_cookie_if_present
    locale = cookies[:locale]

    return locale.to_sym if valid_locale?(locale)

    log_invalid_locale(locale)
    nil
  end

  def set_locale_cookie_if_present
    cookies.permanent[:locale] = params[:locale] if params[:locale].present?
  end

  def valid_locale?(locale)
    I18n.available_locales.map(&:to_s).include?(locale)
  end

  def log_invalid_locale(locale)
    notice = "#{locale} #{I18n.t(:no_translation)}"
    # flash.now[:notice] = notice
    logger.error notice
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
