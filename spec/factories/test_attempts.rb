# spec/factories/test_attempts.rb
FactoryBot.define do
  factory :test_attempt do
    association :user
    association :test, :theoretical
    started_at { Time.current }
    access_code { SecureRandom.hex(8) }
    passed { false }

    trait :completed do
      completed_at { Time.current }
    end

    trait :passed do
      passed { true }
      completed_at { Time.current }
    end
  end
end
