require "csv"

module InventoryTrackingEvents
  class CsvImporter
    REQUIRED_HEADERS = ["Address", "Product Name", "Date", "Inventory Present"].freeze
    BATCH_SIZE = 1_000

    def initialize(path)
      @path = path
    end

    def call
      validate_headers!

      row_count = 0
      created_count = 0

      InventoryTrackingEvent.transaction do
        CSV.foreach(@path, headers: true).each_slice(BATCH_SIZE) do |rows|
          row_count += rows.size

          addresses = rows.map { |row| row["Address"] }.uniq
          product_names = rows.map { |row| row["Product Name"] }.uniq

          store_ids_by_address = Store.where(address: addresses).pluck(:address, :id).to_h
          product_ids_by_name = Product.where(name: product_names).pluck(:name, :id).to_h

          event_attributes = rows.filter_map do |row|
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

          InventoryTrackingEvent.insert_all!(event_attributes)
          created_count += event_attributes.size
        end
      end

      Rails.logger.info "[InventoryTrackingEvents::CsvImporter] rows processed=#{row_count} created=#{created_count}"
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

      if supported_truthy_values.include?(value)
        true
      elsif supported_falsy_values.include?(value)
        false
      else
        raise ArgumentError, "CSV contains unaccounted for boolean values! Cannot import it!"
      end
    end
  end
end
