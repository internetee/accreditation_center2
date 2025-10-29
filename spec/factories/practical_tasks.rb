# spec/factories/practical_tasks.rb
FactoryBot.define do
  factory :practical_task do
    sequence(:title_et) { |n| "Praktiline ülesanne #{n}" }
    sequence(:title_en) { |n| "Practical task #{n}" }
    sequence(:body_et) { |n| "Kirjeldus ülesandele #{n}" }
    sequence(:body_en) { |n| "Description for task #{n}" }
    display_order { 1 }
    association :test
    active { true }
  end
end
