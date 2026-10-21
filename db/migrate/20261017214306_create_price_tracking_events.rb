class CreatePriceTrackingEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :price_tracking_events do |t|
      t.references :product, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.datetime :event_time, null: false
      t.monetize :price,
        amount: { null: false },
        currency: { present: false } # No currency column - defaults to USD
      t.timestamps
    end

    add_index :price_tracking_events, [:product_id, :store_id, :event_time, :id],
              name: "index_price_tracking_events_on_product_store_history"
  end
end
