class AddVarsToTestAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :test_attempts, :vars, :jsonb, default: {}, null: false
    add_index  :test_attempts, :vars, using: :gin
  end
end
