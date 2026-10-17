class AddNullFalseConstraintToTrackingEventsEventTime < ActiveRecord::Migration[7.1]
  def change
    change_column_null :tracking_events, :event_time, false
  end
end
