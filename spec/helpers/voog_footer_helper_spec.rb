# frozen_string_literal: true

require "rails_helper"

RSpec.describe VoogFooterHelper, type: :helper do
  describe "#footer_link_url" do
    it "returns i18n cookie settings URL even when Voog contains cookie policy link" do
      allow(VoogFooter).to receive(:configuration).and_return(
        instance_double(VoogFooter::Configuration, enabled: true, site_url: "https://www.internet.ee")
      )
      allow(VoogFooter).to receive(:structure).and_return(
        "en" => {
          "columns" => [
            {
              "links" => [
                { "key" => "cookie_settings", "url" => "https://voog.example/cookies", "text" => "Voog Cookies" }
              ],
              "social_links" => []
            }
          ]
        }
      )

      expect(helper.footer_link_url(:cookie_settings)).to eq("javascript:void(0)")
    end
  end

  describe "#footer_navigation_columns" do
    it "keeps Voog column order and injects cookie settings after content management" do
      allow(VoogFooter).to receive(:configuration).and_return(
        instance_double(VoogFooter::Configuration, enabled: true, site_url: "https://www.internet.ee")
      )
      allow(VoogFooter).to receive(:structure).and_return(
        "en" => {
          "columns" => [
            {
              "name" => "Help and info",
              "links" => [
                { "key" => "faq", "url" => "https://www.internet.ee/faq", "text" => "FAQ" },
                {
                  "key" => "principles_for_the_content_management_of_estonian_internet",
                  "url" => "https://www.internet.ee/content",
                  "text" => "Content"
                },
                { "key" => "cookie_settings", "url" => "https://voog.example/cookies", "text" => "Voog Cookies" }
              ],
              "social_links" => []
            },
            {
              "name" => "Registrars",
              "links" => [
                { "key" => "accredited_registrars", "url" => "https://www.internet.ee/registrars", "text" => "Registrars" }
              ],
              "social_links" => []
            },
            {
              "follow_us" => true,
              "name" => "Follow us!",
              "links" => [],
              "social_links" => []
            }
          ]
        }
      )

      columns = helper.footer_navigation_columns
      help_links = columns.first[:links]
      cookie = help_links.find { |link| link[:key] == :cookie_settings }

      expect(columns.map { |column| column[:name] }).to eq(["Help and info", "Registrars"])
      expect(help_links.map { |link| link[:label] }).to eq(["FAQ", "Content Management", "Cookie Settings"])
      expect(cookie[:url]).to eq("javascript:void(0)")
      expect(cookie[:html_options]).to include(
        target: "_blank",
        rel: "noopener",
        title: "Cookie Settings",
        "data-cc": "show-preferencesModal",
        "aria-haspopup": "dialog"
      )
    end
  end

  describe "#footer_social_links" do
    it "maps social icons from URL host when Voog key is path-derived" do
      allow(VoogFooter).to receive(:configuration).and_return(
        instance_double(VoogFooter::Configuration, enabled: true, site_url: "https://www.internet.ee")
      )
      allow(VoogFooter).to receive(:structure).and_return(
        "en" => {
          "columns" => [
            {
              "follow_us" => true,
              "name" => "Follow us!",
              "social_links" => [
                { "key" => "eestiinternet", "url" => "https://www.facebook.com/EestiInternet", "icon" => { "name" => nil } },
                { "key" => "eesti_internet", "url" => "https://twitter.com/Eesti_Internet", "icon" => { "name" => nil } }
              ]
            }
          ]
        }
      )

      links = helper.footer_social_links

      expect(links.map { |link| link[:key] }).to eq(%i[facebook twitter])
      expect(links.map { |link| link[:icon_class] }).to eq(["fab fa-facebook-square", "fab fa-twitter"])
    end
  end
end
