# spec/factories/test_categories.rb
FactoryBot.define do
  factory :test_category do
    sequence(:name_et) { |n| "Kategooria #{n}" }
    sequence(:name_en) { |n| "Category #{n}" }
    questions_per_category { 5 }
    domain_rule_url { 'https://google.com' }
    active { true }
  end
end
