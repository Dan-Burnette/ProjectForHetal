class AddNullFalseConstraintForProductName < ActiveRecord::Migration[7.1]
  def change
    change_column_null :products, :name, false
  end
end
