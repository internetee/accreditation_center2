class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.references :test_category, null: false, foreign_key: true
      t.text :text_et, null: false
      t.text :text_en, null: false
      t.text :help_text_et
      t.text :help_text_en
      t.string :question_type, null: false, default: 'multiple_choice'
      t.integer :display_order, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :questions, :question_type
    add_index :questions, [:test_category_id, :display_order], unique: true
    add_index :questions, :active
  end
end
