class NoInventoryAlert < ApplicationRecord
  belongs_to :product
  belongs_to :store
  has_one :brand, through: :product

  validates :failed_checks, numericality: true
  validates :first_failure_at, :last_failure_at, presence: true
end
