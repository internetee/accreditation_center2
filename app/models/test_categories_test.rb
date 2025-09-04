class TestCategoriesTest < ApplicationRecord
  belongs_to :test
  belongs_to :test_category

  positioned on: :test, column: :display_order

  validates :test_id, uniqueness: { scope: :test_category_id }

  # # Helper methods for easier positioning
  # def self.add_category_to_test(test, test_category, position = nil)
  #   join_record = find_or_create_by(test: test, test_category: test_category)
  #   if position
  #     join_record.update(display_order: position)
  #   end
  #   join_record
  # end

  # def self.remove_category_from_test(test, test_category)
  #   find_by(test: test, test_category: test_category)&.destroy
  # end
end
