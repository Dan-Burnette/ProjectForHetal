class NoInventoryAlertsController < ApplicationController
  def index
    @pagy, @no_inventory_alerts = pagy(
      NoInventoryAlert.includes(:store, product: :brand)
        .order(last_failure_at: :desc, id: :desc),
      limit: 25
    )
  end

  def show
    @no_inventory_alert = NoInventoryAlert.includes(:store, product: :brand).find(params[:id])
  end
end
