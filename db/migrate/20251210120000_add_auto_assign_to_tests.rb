class AddAutoAssignToTests < ActiveRecord::Migration[8.0]
  def change
    add_column :tests, :auto_assign, :boolean, default: false, null: false
  end
end
