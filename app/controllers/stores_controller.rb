class StoresController < ApplicationController
  def index
    @pagy, @stores = pagy(Store.all, limit: 25)
    @inventory_event_counts = InventoryTrackingEvent
      .where(store_id: @stores.pluck(:id))
      .group(:store_id)
      .count
  end

  def show
    @store = Store.find(params[:id])
    @pagy, @inventory_tracking_events = pagy(
      @store.inventory_tracking_events
        .by_recency
        .includes(product: :brand),
      limit: 25
    )
  end
end
