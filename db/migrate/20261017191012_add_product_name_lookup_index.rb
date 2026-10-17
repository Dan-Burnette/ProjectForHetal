class AddProductNameLookupIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :products, :name, unique: true, algorithm: :concurrently
  end
end
