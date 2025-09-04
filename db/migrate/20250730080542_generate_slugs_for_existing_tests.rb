class GenerateSlugsForExistingTests < ActiveRecord::Migration[8.0]
  def up
    Test.find_each(&:save)
  end

  def down
    # This migration cannot be reversed as it only generates slugs
  end
end
