class CreateTestCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :test_categories do |t|
      t.references :test, null: false, foreign_key: true
      t.string :name_et, null: false
      t.string :name_en, null: false
      t.text :description_et
      t.text :description_en
      t.string :domain_rule_reference, null: false
      t.integer :questions_per_category, null: false, default: 5
      t.integer :display_order, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :test_categories, :domain_rule_reference
    add_index :test_categories, :display_order
    add_index :test_categories, :active
  end
end
