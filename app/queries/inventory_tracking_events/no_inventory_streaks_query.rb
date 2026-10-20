class InventoryTrackingEvents::NoInventoryStreaksQuery
  # product_store_pairs is an array of [product_id, store_id] pairs.
  def initialize(product_store_pairs)
    @product_store_pairs = product_store_pairs
  end

  # Returns symbol-keyed hashes for completed and ongoing streaks of at least
  # two failures, ordered by product, store, then streak chronology.
  # Each hash contains product_id, store_id, failed_checks, first_failure_at,
  # and last_failure_at. Equal event_times are ordered by event ID.
  def call
    return [] if @product_store_pairs.empty?

    events = InventoryTrackingEvent.where([:product_id, :store_id] => @product_store_pairs)

    # Each successful check starts a new group. Keep successes in the window
    # calculation so they separate failures, then aggregate only the failures.
    sql = <<~SQL
      WITH grouped_events AS (
        SELECT product_id, store_id, event_time, inventory_present,
               COUNT(*) FILTER (WHERE inventory_present) OVER (
                 PARTITION BY product_id, store_id
                 ORDER BY event_time, id
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
               ) AS streak_group
        FROM (#{events.to_sql}) AS events
      )
      SELECT product_id, store_id,
             COUNT(*) AS failed_checks,
             MIN(event_time) AS first_failure_at,
             MAX(event_time) AS last_failure_at
      FROM grouped_events
      WHERE inventory_present = FALSE
      GROUP BY product_id, store_id, streak_group
      HAVING COUNT(*) >= 2
      ORDER BY product_id, store_id, streak_group
    SQL

    InventoryTrackingEvent.connection.select_all(sql).map(&:symbolize_keys)
  end
end
