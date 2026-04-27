# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.test" }
    provider { 'oidc' }
    sequence(:uid) { |n| "EE#{format('%011d', n)}" }
    sequence(:name) { |n| "Example User #{n}" }
    sequence(:username) { |n| "user#{n}" }

    transient do
      sequence(:registrar_name) { |n| "Example Registrar #{n}" }
      sequence(:registrar_email) { |n| "registrar#{n}@example.test" }
      registrar_accreditation_date { nil }
      registrar_accreditation_expire_date { nil }
    end

    after(:build) do |user, evaluator|
      next if evaluator.registrar_name.blank?

      user.registrar ||= Registrar.find_or_initialize_by(name: evaluator.registrar_name)
      user.registrar.email = evaluator.registrar_email if evaluator.registrar_email.present?
      user.registrar.accreditation_date = evaluator.registrar_accreditation_date if evaluator.registrar_accreditation_date.present?
      if evaluator.registrar_accreditation_expire_date.present?
        user.registrar.accreditation_expire_date = evaluator.registrar_accreditation_expire_date
      end
    end

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
