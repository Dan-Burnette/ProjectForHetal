class Store < ApplicationRecord
  has_many :inventory_tracking_events
  has_many :price_tracking_events

  # In real life you may want to validate the address more deeply, e.g with 
  # https://github.com/ankane/mainstreet
  validates :address, presence: true, uniqueness: true
end
