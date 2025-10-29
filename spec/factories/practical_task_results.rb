# spec/factories/practical_task_results.rb
FactoryBot.define do
  factory :practical_task_result do
    association :test_attempt
    association :practical_task
    status { 'passed' }
  end
end
