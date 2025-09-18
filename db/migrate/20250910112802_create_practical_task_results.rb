class CreatePracticalTaskResults < ActiveRecord::Migration[8.0]
  def change
    create_table :practical_task_results do |t|
      t.bigint :test_attempt_id, null: false
      t.bigint :practical_task_id, null: false
      t.string :status, null: false, default: "pending" # pending|running|passed|failed
      t.jsonb :inputs, default: {}          # user-supplied IDs, etc.
      t.jsonb :result, default: {}          # { score, evidence, error, api_audit, export_vars }
      t.datetime :validated_at
      t.timestamps
    end
    add_index :practical_task_results, [:test_attempt_id, :practical_task_id], unique: true, name: "idx_ptr_on_attempt_and_task"
    add_index :practical_task_results, :status
    add_foreign_key :practical_task_results, :test_attempts
    add_foreign_key :practical_task_results, :practical_tasks
  end
end
