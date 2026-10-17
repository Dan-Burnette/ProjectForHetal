class InventoryTrackingEvent < ApplicationRecord
  include TrackableEvent

  validates :inventory_present, inclusion: { in: [true, false] }
end
