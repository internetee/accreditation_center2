import { Controller } from "@hotwired/stimulus"
import * as CookieConsent from "vanilla-cookieconsent"

export default class extends Controller {
  connect() {
    CookieConsent.run({
      revision: 1,
      disablePageInteraction: false,
      guiOptions: {
        consentModal: {
          layout: "bar",
          position: "bottom",
          equalWeightButtons: true,
          flipButtons: true
        },
        preferencesModal: {
          layout: "box",
          position: "right",
          equalWeightButtons: true,
          flipButtons: true
        }
      },
      categories: {
        necessary: {
          enabled: true,  // this category is enabled by default
          readOnly: true  // this category cannot be disabled
        },
      },
      language: {
        default: 'en',
        autoDetect: "document",
        translations: {
          en: {
            consentModal: {
              title: "This website uses cookies",
              description: 'We use cookies to collect and analyse information on site performance and usage, to enhance and customise content. Read more <a class=\"cc__link\" href="https://www.internet.ee/eif/cookies-on-internet-ee-webpage" target="_blank">here</a>.',
              acceptAllBtn: "ACCEPT ALL",
              acceptNecessaryBtn: "REJECT ALL",
              showPreferencesBtn: "Cookie Settings"
            },
            preferencesModal: {
              title: "Manage cookie preferences",
              acceptAllBtn: "ACCEPT ALL",
              acceptNecessaryBtn: "REJECT ALL",
              savePreferencesBtn: "Accept current selection",
              closeIconLabel: "Close",
              sections: [
                {
                  title: "Cookie Usage",
                  description: "We use cookies to help you navigate efficiently and perform certain functions. You will find detailed information about all cookies under each consent category below. The cookies that are categorized as \"Necessary\" are stored on your browser as they are essential for enabling the basic functionalities of the site."
                },
                {
                  title: "Strictly Necessary Cookies <span class=\"pm__badge\">Always Enabled</span>",
                  description: "The website cannot function properly without these cookies. As these cookies are needed for the secure provision of services, the visitor cannot refuse them.",
                  linkedCategory: "necessary"
                },
                {
                  title: "More information",
                  description: "For any query in relation to my policy on cookies and your choices, please <a class=\"cc__link\" href=\"mailto:info@internet.ee\">contact us</a>."
                }
              ],
            }
          },
          et: {
            consentModal: {
              title: "See veebileht kasutab küpsiseid",
              description: 'Kasutame küpsiseid, et koguda ja analüüsida veebilehe jõudluse ja kasutuse teavet ning parandada ja isikupärastada sisu. Loe lisateavet <a class=\"cc__link\" href="https://www.internet.ee/eis/kupsised-internet-ee-lehel" target="_blank">siit</a>.',
              acceptAllBtn: "LUBA KÕIK",
              acceptNecessaryBtn: "KEELDU",
              showPreferencesBtn: "Küpsiste seaded",
            },
            preferencesModal: {
              title: "Küpsiste seaded",
              acceptAllBtn: "LUBA KÕIK",
              acceptNecessaryBtn: "KEELDU",
              savePreferencesBtn: "Salvesta valik",
              closeIconLabel: "Sulge",
              sections: [
                {
                  title: "Küpsiste kasutamine",
                  description: "Kasutame küpsiseid, et aidata Teil tõhusalt navigeerida ja teatud funktsioone täita. Üksikasjalikku teavet kõigi küpsiste kohta leiate allpool iga nõusolekukategooria alt. Küpsistest, mis on liigitatud kui \"Vajalikud\", ei saa loobuda, sest need on olulised saidi põhifunktsioonide võimaldamiseks."
                },
                {
                  title: "Vajalikud küpsised <span class=\"pm__badge\">Alati lubatud</span>",
                  description: "Veebileht ei saa ilma nende küpsisteta korralikult toimida. Seetõttu ei ole külastajal võimalik neist keelduda.",
                  linkedCategory: "necessary"
                },
                {
                  title: "Lisateave",
                  description: "Küsimusi küpsiste seadistuste ja Teie valikute kohta saate <a class=\"cc__link\" href=\"mailto:info@internet.ee\">meile kontakteerida</a>."
                }
              ]
            }
          }
        }
      }
    });
  }
}