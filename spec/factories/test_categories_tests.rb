# spec/factories/test_categories_tests.rb
FactoryBot.define do
  factory :test_categories_test do
    association :test
    association :test_category
  end
end
