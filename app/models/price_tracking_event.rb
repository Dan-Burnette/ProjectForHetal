class PriceTrackingEvent < ApplicationRecord
  include TrackableEvent

  # Defaults to USD, we are assuming all data comes in as USD
  monetize :price_cents, allow_nil: false, numericality: { greater_than: 0 }

  validates :price, presence: true
end
