class AddNullFalseConstraintForStoreAddress < ActiveRecord::Migration[7.1]
  def change
    change_column_null :stores, :address, false
  end
end
