class AddProductStoreHistoryIndexToInventoryTrackingEvents < ActiveRecord::Migration[7.1]
  def change
    add_index :inventory_tracking_events, [:product_id, :store_id, :event_time, :id],
              name: "index_inventory_tracking_events_on_product_store_history"
  end
end
