class RegistrarNotificationEvent < ApplicationRecord
  belongs_to :registrar

  validates :event_type, :cycle_key, :sent_at, presence: true
  validates :cycle_key,
            uniqueness: { scope: [:registrar_id, :event_type] }
end
