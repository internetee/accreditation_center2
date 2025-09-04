class AddDisplayOrderToTestCategoriesTests < ActiveRecord::Migration[8.0]
  def up
    # Add the display_order column
    add_column :test_categories_tests, :display_order, :integer, null: false, default: 0

    # Update existing records to have unique display_order values per test
    execute <<-SQL
      UPDATE test_categories_tests 
      SET display_order = subquery.row_number
      FROM (
        SELECT test_id, test_category_id, ROW_NUMBER() OVER (PARTITION BY test_id ORDER BY test_category_id) as row_number
        FROM test_categories_tests
      ) as subquery
      WHERE test_categories_tests.test_id = subquery.test_id 
        AND test_categories_tests.test_category_id = subquery.test_category_id
    SQL

    # Add the unique index after ensuring no duplicates
    add_index :test_categories_tests, [:test_id, :display_order], unique: true
  end

  def down
    remove_index :test_categories_tests, [:test_id, :display_order]
    remove_column :test_categories_tests, :display_order
  end
end
