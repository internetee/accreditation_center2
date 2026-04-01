class AddBackUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string unless column_exists?(:users, :username)
    add_index :users, :username, unique: true, where: "username IS NOT NULL" unless index_exists?(:users, :username, unique: true, where: "username IS NOT NULL")
  end
end
