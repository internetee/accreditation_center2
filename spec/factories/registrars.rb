FactoryBot.define do
  factory :registrar do
    sequence(:name) { |n| "Registrar #{n}" }
  end
end
