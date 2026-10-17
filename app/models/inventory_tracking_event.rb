class InventoryTrackingEvent < ApplicationRecord
  belongs_to :product
  belongs_to :store

  validates :event_time, presence: true
  validates :inventory_present, inclusion: { in: [true, false] }
end
