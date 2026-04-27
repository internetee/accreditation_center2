FactoryBot.define do
  factory :registrar_notification_event do
    association :registrar
    event_type { 'accreditation_granted' }
    cycle_key { 'pending_accreditation' }
    sent_at { Time.current }
  end
end
