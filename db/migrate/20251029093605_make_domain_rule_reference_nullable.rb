class MakeDomainRuleReferenceNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :test_categories, :domain_rule_reference, true
  end
end
