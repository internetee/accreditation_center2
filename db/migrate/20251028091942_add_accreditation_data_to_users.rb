class AddAccreditationDataToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :accreditation_date, :datetime
    add_column :users, :accreditation_expire_date, :datetime
  end
end
