# spec/factories/questions.rb
FactoryBot.define do
  factory :question do
    sequence(:text_et) { |n| "Küsimus #{n}?" }
    sequence(:text_en) { |n| "Question #{n}?" }
    association :test_category
    question_type { 'multiple_choice' }
    display_order { 1 }
    active { true }
  end
end
