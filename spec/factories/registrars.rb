FactoryBot.define do
  factory :registrar do
    sequence(:name) { |n| "Registrar #{n}" }
    sequence(:email) { |n| "registrar#{n}@example.test" }
  end
end
