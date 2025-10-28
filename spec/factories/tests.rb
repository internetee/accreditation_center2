# spec/factories/tests.rb
FactoryBot.define do
  factory :test do
    sequence(:title_et) { |n| "Test #{n}" }
    sequence(:title_en) { |n| "Test #{n}" }
    passing_score_percentage { 100 }
    time_limit_minutes { 60 }
    active { true }

    trait :theoretical do
      test_type { :theoretical }
    end

    trait :practical do
      test_type { :practical }
    end
  end
end
