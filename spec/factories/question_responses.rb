# spec/factories/question_responses.rb
FactoryBot.define do
  factory :question_response do
    association :test_attempt
    association :question
    selected_answer_ids { [1] }
    marked_for_later { false }
  end
end
