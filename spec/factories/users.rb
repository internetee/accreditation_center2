# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.test" }
    sequence(:registrar_name) { |n| "Example Registrar #{n}" }
    provider { 'oidc' }
    sequence(:uid) { |n| "EE#{format('%011d', n)}" }
    sequence(:name) { |n| "Example User #{n}" }
    sequence(:username) { |n| "user#{n}" }

    trait :admin do
      sequence(:email) { |n| "admin#{n}@example.test" }
      name { 'Admin User' }
      registrar_name { nil }
      role { :admin }
      password { 'AdminPass123!' }
      password_confirmation { 'AdminPass123!' }
    end
  end
end
