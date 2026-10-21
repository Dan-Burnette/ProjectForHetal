class ProductsController < ApplicationController
  def index
    @pagy, @products = pagy(Product.includes(:brand), limit: 25)
    @inventory_event_counts = InventoryTrackingEvent
      .where(product_id: @products.pluck(:id))
      .group(:product_id)
      .count
  end

  def show
    @product = Product.includes(:brand).find(params[:id])
    @pagy, @inventory_tracking_events = pagy(
      @product.inventory_tracking_events
        .by_recency
        .includes(:store),
      limit: 25
    )
  end
end
