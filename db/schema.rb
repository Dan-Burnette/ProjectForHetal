# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_10_20_232837) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brands", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_brands_on_name", unique: true
  end

  create_table "inventory_tracking_events", force: :cascade do |t|
    t.boolean "inventory_present", null: false
    t.bigint "product_id", null: false
    t.bigint "store_id", null: false
    t.datetime "event_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "store_id", "event_time", "id"], name: "index_inventory_tracking_events_on_product_store_history"
    t.index ["product_id"], name: "index_inventory_tracking_events_on_product_id"
    t.index ["store_id"], name: "index_inventory_tracking_events_on_store_id"
  end

  create_table "no_inventory_alerts", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "store_id", null: false
    t.integer "failed_checks", null: false
    t.datetime "first_failure_at", null: false
    t.datetime "last_failure_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "store_id"], name: "index_no_inventory_alerts_on_product_id_and_store_id"
    t.index ["product_id"], name: "index_no_inventory_alerts_on_product_id"
    t.index ["store_id"], name: "index_no_inventory_alerts_on_store_id"
  end

  create_table "price_tracking_events", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "store_id", null: false
    t.datetime "event_time", null: false
    t.integer "price_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "store_id", "event_time", "id"], name: "index_price_tracking_events_on_product_store_history"
    t.index ["product_id"], name: "index_price_tracking_events_on_product_id"
    t.index ["store_id"], name: "index_price_tracking_events_on_store_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "brand_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["name"], name: "index_products_on_name", unique: true
  end

  create_table "stores", force: :cascade do |t|
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_stores_on_address", unique: true
  end

  add_foreign_key "inventory_tracking_events", "products"
  add_foreign_key "inventory_tracking_events", "stores"
  add_foreign_key "no_inventory_alerts", "products"
  add_foreign_key "no_inventory_alerts", "stores"
  add_foreign_key "price_tracking_events", "products"
  add_foreign_key "price_tracking_events", "stores"
  add_foreign_key "products", "brands"
end
