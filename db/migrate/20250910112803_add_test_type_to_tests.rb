class AddTestTypeToTests < ActiveRecord::Migration[8.0]
  def change
    add_column :tests, :test_type, :integer, default: 0, null: false
    add_index :tests, :test_type
  end
end
