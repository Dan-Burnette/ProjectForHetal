class CreateNoInventoryAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :no_inventory_alerts do |t|
      t.references :product, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.integer :failed_checks, null: false
      t.datetime :first_failure_at, null: false
      t.datetime :last_failure_at, null: false

      t.timestamps

      t.index [:product_id, :store_id]
    end
  end
end
