class CreateRegistrarsAndMoveUserRegistrarData < ActiveRecord::Migration[8.0]
  DEFAULT_REGISTRAR_NAME = "Unassigned Registrar".freeze

  def up
    create_table :registrars do |t|
      t.string :name, null: false
      t.string :email
      t.datetime :accreditation_date
      t.datetime :accreditation_expire_date
      t.timestamps
    end

    add_index :registrars, "LOWER(name)", unique: true, name: "index_registrars_on_lower_name"

    add_reference :users, :registrar, null: true, foreign_key: true

    remove_index :users, :registrar_name if index_exists?(:users, :registrar_name)
    remove_column :users, :registrar_name, :string if column_exists?(:users, :registrar_name)
    remove_column :users, :registrar_accreditation_date, :datetime if column_exists?(:users, :registrar_accreditation_date)
    remove_column :users, :registrar_accreditation_expire_date, :datetime if column_exists?(:users, :registrar_accreditation_expire_date)
  end

  def down
    add_column :users, :registrar_name, :string unless column_exists?(:users, :registrar_name)
    add_column :users, :registrar_accreditation_date, :datetime unless column_exists?(:users, :registrar_accreditation_date)
    add_column :users, :registrar_accreditation_expire_date, :datetime unless column_exists?(:users, :registrar_accreditation_expire_date)
    add_index :users, :registrar_name unless index_exists?(:users, :registrar_name)

    remove_reference :users, :registrar, foreign_key: true if column_exists?(:users, :registrar_id)
    drop_table :registrars, if_exists: true
  end
end
