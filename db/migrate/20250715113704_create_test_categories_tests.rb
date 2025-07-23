class CreateTestCategoriesTests < ActiveRecord::Migration[8.0]
  def change
    create_table :test_categories_tests, id: false do |t|
      t.references :test, null: false, foreign_key: true
      t.references :test_category, null: false, foreign_key: true
    end

    add_index :test_categories_tests, [:test_id, :test_category_id], unique: true
  end
end
