class AddRegistrarNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :registrar_name, :string
    add_index  :users, :registrar_name
  end
end
