class CreatePracticalTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :practical_tasks do |t|
      t.bigint :test_id, null: false
      t.string :title_en, null: true
      t.string :title_et, null: true
      t.text   :body_en,  null: false           # instructions (you can switch to ActionText later)
      t.text   :body_et,  null: false
      t.jsonb  :validator, default: {}          # { "klass": "...", "config": {...}, "input_fields": [...], "required": true, "weight": 1.0, "depends_on_task_ids": [..] }
      t.integer :display_order, null: false, default: 0
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :practical_tasks, :test_id
    add_index :practical_tasks, :display_order
    add_foreign_key :practical_tasks, :tests
  end
end
