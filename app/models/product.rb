class Product < ApplicationRecord
  belongs_to :brand
  has_many :inventory_tracking_events
  has_many :price_tracking_events

  validates :name, presence: true, uniqueness: true
end
