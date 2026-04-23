class RenameUserAccreditationFieldsToRegistrarFields < ActiveRecord::Migration[8.0]
  def up
    if column_exists?(:users, :accreditation_date) && !column_exists?(:users, :registrar_accreditation_date)
      rename_column :users, :accreditation_date, :registrar_accreditation_date
    end

    if column_exists?(:users, :accreditation_expire_date) && !column_exists?(:users, :registrar_accreditation_expire_date)
      rename_column :users, :accreditation_expire_date, :registrar_accreditation_expire_date
    end
  end

  def down
    if column_exists?(:users, :registrar_accreditation_date) && !column_exists?(:users, :accreditation_date)
      rename_column :users, :registrar_accreditation_date, :accreditation_date
    end

    if column_exists?(:users, :registrar_accreditation_expire_date) && !column_exists?(:users, :accreditation_expire_date)
      rename_column :users, :registrar_accreditation_expire_date, :accreditation_expire_date
    end
  end
end
