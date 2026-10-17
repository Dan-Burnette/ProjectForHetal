class Store < ApplicationRecord
  has_many :tracking_events

  validates :address, presence: true, uniqueness: true
end
