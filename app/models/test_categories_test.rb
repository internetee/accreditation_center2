class TestCategoriesTest < ApplicationRecord
  belongs_to :test
  belongs_to :test_category

  positioned on: :test, column: :display_order

  validates :test_id, uniqueness: { scope: :test_category_id }
end
