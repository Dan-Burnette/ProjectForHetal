require "csv"

module InventoryTrackingEvents
  class CsvImporter
    REQUIRED_HEADERS = ["Address", "Product Name", "Date", "Inventory Present"].freeze
    BATCH_SIZE = 10_000
    IMPORT_LOCK_NAME = "inventory_tracking_events_csv_import".freeze

    def initialize(path)
      @path = path
    end

    def setup_progress_tracking
      @row_count = 0
      @created_count = 0
      @product_store_pairs = []
    end

    def call
      validate_headers!
      setup_progress_tracking

      ActiveRecord::Base.transaction do
        InventoryTrackingEvent.with_advisory_lock!(IMPORT_LOCK_NAME, transaction: true) do
          CSV.foreach(@path, headers: true).each_slice(BATCH_SIZE).with_index(1) do |rows, batch_number|
            event_attributes = build_tracking_event_attrs_for(rows)
            InventoryTrackingEvent.insert_all!(event_attributes)
            track_progress(rows, batch_number, event_attributes)
          end

          InventoryTrackingEvents::ReconcileNoInventoryAlerts.new(@product_store_pairs).call
        end
      end

      puts "[InventoryTrackingEvents::CsvImporter] import complete!"
    end

    private

    def validate_headers!
      headers = CSV.open(@path) { |csv| csv.shift } || []
      missing_headers = REQUIRED_HEADERS - headers
      return if missing_headers.empty?

      raise ArgumentError, "CSV is missing required columns: #{missing_headers.join(', ')}"
    end

    def cast_boolean!(value)
      supported_truthy_values = ["True"]
      supported_falsy_values = ["False"]

      return true if supported_truthy_values.include?(value)
      return false if supported_falsy_values.include?(value)
      raise ArgumentError, "CSV contains unaccounted for boolean values! Cannot import it!"
    end

    def build_tracking_event_attrs_for(rows)
      addresses = rows.map { |row| row["Address"] }.uniq
      product_names = rows.map { |row| row["Product Name"] }.uniq

      store_ids_by_address = Store.where(address: addresses).pluck(:address, :id).to_h
      product_ids_by_name = Product.where(name: product_names).pluck(:name, :id).to_h

      rows.filter_map do |row|
        store_id = store_ids_by_address[row["Address"]]
        product_id = product_ids_by_name[row["Product Name"]]
        next unless store_id && product_id

        {
          store_id: store_id,
          product_id: product_id,
          event_time: Date.parse(row["Date"]),
          inventory_present: cast_boolean!(row["Inventory Present"])
        }
      end
    end

    def track_progress(rows, batch_number, event_attributes)
      @row_count += rows.size
      @created_count += event_attributes.size
      @product_store_pairs += event_attributes.map do |attrs|
        [attrs[:product_id], attrs[:store_id] ]
      end

      puts "[InventoryTrackingEvents::CsvImporter] batch #{batch_number}/#{total_batches} processed=#{@row_count} created=#{@created_count}"
    end

    def total_rows
      @total_rows ||= CSV.foreach(@path, headers: true).count
    end

    def total_batches
      (total_rows + BATCH_SIZE - 1) / BATCH_SIZE
    end
  end
end
