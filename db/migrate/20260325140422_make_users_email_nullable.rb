class MakeUsersEmailNullable < ActiveRecord::Migration[8.0]
  def up
    change_column_null :users, :email, true
    remove_index :users, name: "index_users_on_email", if_exists: true
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
