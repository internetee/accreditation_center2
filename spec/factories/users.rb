# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.test" }
    registrar_name { 'Example Registrar' }
    provider { 'oidc' }
    sequence(:uid) { |n| "EE#{format('%011d', n)}" }
    sequence(:name) { |n| "Example User #{n}" }
    sequence(:username) { |n| "user#{n}" }

    trait :admin do
      email { 'admin@example.test' }
      provider { 'oidc' }
      sequence(:uid) { |n| "EEA#{format('%010d', n)}" }
      name { 'Admin User' }
      registrar_name { nil }
      role { :admin }
    end
  end
end
