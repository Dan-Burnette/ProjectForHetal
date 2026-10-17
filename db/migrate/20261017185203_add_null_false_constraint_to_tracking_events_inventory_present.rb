class AddNullFalseConstraintToTrackingEventsInventoryPresent < ActiveRecord::Migration[7.1]
  def change
    change_column_null :tracking_events, :inventory_present, false
  end
end
