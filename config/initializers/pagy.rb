# Instance variables
# See https://ddnexus.github.io/pagy/api/pagy#instance-variables
Pagy::I18n.load({ locale: 'en',
                  filepath: "#{Rails.root}/config/locales/pagy.en.yml" },
                { locale: 'et',
                  filepath: "#{Rails.root}/config/locales/pagy.et.yml" })
Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:size]  = 5
Pagy::DEFAULT[:page_param] = :page
Pagy::DEFAULT[:max_items] = 100
Pagy::DEFAULT.freeze
