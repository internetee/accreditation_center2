# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email)    { |n| "user#{n}@example.test" }
    registrar_name { "Example Registrar" }
    password { "Password1!" }
    password_confirmation { "Password1!" }

    trait :admin do
      role { :admin }
    end
  end
end
