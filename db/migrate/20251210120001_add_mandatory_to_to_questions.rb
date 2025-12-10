class AddMandatoryToToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :mandatory_to, :date
    add_index :questions, :mandatory_to
  end
end
