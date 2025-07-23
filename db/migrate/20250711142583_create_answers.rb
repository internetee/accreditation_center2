class CreateAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :answers do |t|
      t.references :question, null: false, foreign_key: true
      t.text :text_et, null: false
      t.text :text_en, null: false
      t.integer :display_order, null: false
      t.boolean :correct, default: false

      t.timestamps
    end

    add_index :answers, :display_order
    add_index :answers, :correct
  end
end
