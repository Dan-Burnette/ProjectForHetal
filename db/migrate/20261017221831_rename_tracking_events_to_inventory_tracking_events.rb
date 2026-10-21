class RenameTrackingEventsToInventoryTrackingEvents < ActiveRecord::Migration[7.1]
  def change
    rename_table :tracking_events, :inventory_tracking_events
  end
end
