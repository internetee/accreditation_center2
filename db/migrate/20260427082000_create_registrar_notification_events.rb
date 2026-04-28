class CreateRegistrarNotificationEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :registrar_notification_events do |t|
      t.references :registrar, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :cycle_key, null: false
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :registrar_notification_events,
              [:registrar_id, :event_type, :cycle_key],
              unique: true,
              name: "index_registrar_notification_events_on_dedupe_key"
  end
end
