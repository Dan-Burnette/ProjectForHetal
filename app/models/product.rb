class Product < ApplicationRecord
  belongs_to :brand
  has_many :tracking_events

  validates :name, presence: true, uniqueness: true
end
