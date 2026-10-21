module TrackableEvent
  extend ActiveSupport::Concern

  included do
    belongs_to :product
    belongs_to :store

    validates :event_time, presence: true

    scope :by_recency, -> { order(event_time: :desc, id: :desc) }
  end
end
