class CreateQuestionResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :question_responses do |t|
      t.references :test_attempt, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :selected_answer_ids, array: true, default: []
      t.boolean :marked_for_later, default: false
      t.jsonb :practical_response_data

      t.timestamps
    end

    add_index :question_responses, [:test_attempt_id, :question_id], unique: true
    add_index :question_responses, :marked_for_later
    add_index :question_responses, :selected_answer_ids, using: :gin
    add_index :question_responses, :practical_response_data, using: :gin
  end
end
