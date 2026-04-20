# spec/factories/answers.rb
FactoryBot.define do
  factory :answer do
    association :question
    sequence(:text_et) { |n| "Vastus #{n}" }
    sequence(:text_en) { |n| "Answer #{n}" }
    correct { false }
    display_order { 1 }

    trait :correct do
      correct { true }
    end
  end
end
