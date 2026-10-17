class PriceTrackingEvent < ApplicationRecord
  belongs_to :product
  belongs_to :store

  # Defaults to USD, we are assuming all data comes in as USD
  monetize :price_cents, allow_nil: false, numericality: { greater_than: 0 }

  validates :event_time, presence: true
  validates :price, presence: true
end
