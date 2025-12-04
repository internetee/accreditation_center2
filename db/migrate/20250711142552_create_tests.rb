class CreateTests < ActiveRecord::Migration[8.0]
  def change
    create_table :tests do |t|
      t.string :title_et, null: false
      t.string :title_en, null: false
      t.text :description_et, null: false
      t.text :description_en, null: false
      t.integer :time_limit_minutes, null: false, default: 60
      t.integer :passing_score_percentage, null: false, default: 70
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :tests, :active
  end
end
