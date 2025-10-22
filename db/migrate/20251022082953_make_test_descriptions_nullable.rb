class MakeTestDescriptionsNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :tests, :description_et, true
    change_column_null :tests, :description_en, true
  end
end
