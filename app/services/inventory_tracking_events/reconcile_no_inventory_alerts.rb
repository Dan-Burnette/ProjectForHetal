class InventoryTrackingEvents::ReconcileNoInventoryAlerts
  BATCH_SIZE = 1000

  def initialize(product_store_pairs)
    @product_store_pairs = product_store_pairs.uniq
  end

  # We need to wipe the NoInventoryAlerts out and rebuild them because we can't
  # rely on existing alerts being correct after new data is imported.
  def call
    return if @product_store_pairs.empty?

    total_batches = (@product_store_pairs.size + BATCH_SIZE - 1) / BATCH_SIZE
    processed_count = 0
    created_count = 0

    ActiveRecord::Base.transaction do
      @product_store_pairs.each_slice(BATCH_SIZE).with_index(1) do |pairs, batch_number|
        wipe_existing_alerts_for_given_products_and_stores(pairs)
        streaks = no_inventory_streaks_for_given_products_and_stores(pairs)
        NoInventoryAlert.insert_all!(streaks)

        processed_count += pairs.size
        created_count += streaks.size
        puts "[InventoryTrackingEvents::ReconcileNoInventoryAlerts] batch #{batch_number}/#{total_batches} processed #{processed_count} product/store combinations created=#{created_count} alerts"
      end
    end

    puts "[InventoryTrackingEvents::ReconcileNoInventoryAlerts] reconciliation complete!"
  end

  private

  def wipe_existing_alerts_for_given_products_and_stores(product_store_pairs)
    NoInventoryAlert
      .where([:product_id, :store_id] => product_store_pairs)
      .delete_all
  end

  def no_inventory_streaks_for_given_products_and_stores(product_store_pairs)
    InventoryTrackingEvents::NoInventoryStreaksQuery.new(product_store_pairs).call
  end
end
