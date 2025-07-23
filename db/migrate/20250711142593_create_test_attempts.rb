class CreateTestAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :test_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :test, null: false, foreign_key: true
      t.string :access_code, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :score_percentage
      t.boolean :passed

      t.timestamps
    end

    add_index :test_attempts, :access_code, unique: true
    add_index :test_attempts, :started_at
    add_index :test_attempts, :completed_at
    add_index :test_attempts, :passed
  end
end
