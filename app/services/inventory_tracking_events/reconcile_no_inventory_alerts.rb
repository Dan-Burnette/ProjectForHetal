class InventoryTrackingEvents::ReconcileNoInventoryAlerts

  def initialize(product_store_pairs)
    @product_store_pairs = product_store_pairs
  end

  # We need to wipe the NoInventoryAlerts out and rebuild them because we can't
  # rely on existing alerts being correct after new data is imported.
  def call
    return if @product_store_pairs.empty?

    ActiveRecord::Base.transaction do
      wipe_existing_alerts_for_given_products_and_stores
      NoInventoryAlert.insert_all!(no_inventory_streaks_for_given_products_and_stores)
    end
  end

  private

  def wipe_existing_alerts_for_given_products_and_stores
    NoInventoryAlert
      .where([:product_id, :store_id] => @product_store_pairs)
      .delete_all
  end

  def no_inventory_streaks_for_given_products_and_stores
    InventoryTrackingEvents::NoInventoryStreaksQuery.new(@product_store_pairs).call
  end
end
