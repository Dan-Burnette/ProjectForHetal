class BrandsController < ApplicationController
  def index
    @pagy, @brands = pagy(Brand.all, limit: 25)
    @product_counts = Product
      .where(brand_id: @brands.pluck(:id))
      .group(:brand_id)
      .count
  end

  def show
    @brand = Brand.find(params[:id])
    @products = @brand.products.load
    @inventory_event_counts = InventoryTrackingEvent
      .where(product_id: @products.pluck(:id))
      .group(:product_id)
      .count
  end
end
