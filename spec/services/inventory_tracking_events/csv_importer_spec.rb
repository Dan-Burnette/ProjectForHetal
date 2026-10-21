require 'rails_helper'
require 'tempfile'
require_relative '../../support/factory_bot'

RSpec.describe InventoryTrackingEvents::CsvImporter do

  it "raises error when a required CSV header is missing" do
    described_class::REQUIRED_HEADERS.each do |missing_header|
      headers = described_class::REQUIRED_HEADERS - [missing_header]

      Tempfile.create(['inventory_tracking_events', '.csv']) do |file|
        file.write(CSV.generate_line(headers))
        file.flush

        expect { described_class.new(file.path).call }.to raise_error(
          ArgumentError,
          "CSV is missing required columns: #{missing_header}"
        )
      end
    end
  end

  it 'raises an error for an unhandled/unexpected Inventory Present value (rolls back transaction)' do
    store = Store.create!(address: '123 Main Street')
    brand = Brand.create!(name: 'Example Brand')
    product = Product.create!(name: 'Example Product', brand: brand)

    Tempfile.create(['inventory_tracking_events', '.csv']) do |file|
      file.write(CSV.generate_line(described_class::REQUIRED_HEADERS))
      file.write(CSV.generate_line(
        [store.address, product.name, '2025-01-02', 'BAD_INVENTORY_PRESENT_VALUE']
      ))
      file.flush

      expect { described_class.new(file.path).call }.to raise_error(
        ArgumentError,
        'CSV contains unaccounted for boolean values! Cannot import it!'
      )
    end
  end

  it 'raises error when Date is not parseable (rolls back transaction)' do
    store = Store.create!(address: '123 Main Street')
    brand = Brand.create!(name: 'Example Brand')
    product = Product.create!(name: 'Example Product', brand: brand)

    Tempfile.create(['inventory_tracking_events', '.csv']) do |file|
      file.write(CSV.generate_line(described_class::REQUIRED_HEADERS))
      file.write(CSV.generate_line([store.address, product.name, 'invalid-date', 'True']))
      file.flush

      expect { described_class.new(file.path).call }.to raise_error(Date::Error)
    end
  end

  it 'successfully imports test_tracking_events.csv (a shorter, 3 row representative csv)' do
    Rails.application.load_seed

    expect do
      described_class.new(Rails.root.join('spec/fixtures/files/test_tracking_events.csv')).call
    end.to change(InventoryTrackingEvent, :count).by(3)

    first = InventoryTrackingEvent.first
    expect(first.store.address).to eq "18 Salamandastron Beach Road, Western Shores"
    expect(first.product.name).to eq "Paleo-DNA Sequencing Devices"
    expect(first.event_time).to eq Date.parse("2025-01-02")
    expect(first.inventory_present).to eq true

    second = InventoryTrackingEvent.second
    expect(second.store.address).to eq "135 Strickland Propane Road, Arlen, Texas"
    expect(second.product.name).to eq "Nobleman’s Wine Reserve"
    expect(second.event_time).to eq Date.parse("2025-09-16")
    expect(second.inventory_present).to eq true

    third = InventoryTrackingEvent.third
    expect(third.store.address).to eq "6 Kandra Alley, Fadrex City"
    expect(third.product.name).to eq "Abbey October Ale"
    expect(third.event_time).to eq Date.parse("2025-10-07")
    expect(third.inventory_present).to eq false
  end

  it 'triggers ReconcileNoInventoryAlerts for the proper product/store pairs' do
    Rails.application.load_seed

    product_one = Product.find_by(name: "Paleo-DNA Sequencing Devices")
    store_one = Store.find_by(address: "18 Salamandastron Beach Road, Western Shores")

    product_two = Product.find_by(name: "Nobleman’s Wine Reserve")
    store_two = Store.find_by(address: "135 Strickland Propane Road, Arlen, Texas")

    product_three = Product.find_by(name: "Abbey October Ale")
    store_three = Store.find_by(address: "6 Kandra Alley, Fadrex City")

    reconciler = instance_double(InventoryTrackingEvents::ReconcileNoInventoryAlerts)
    expect(InventoryTrackingEvents::ReconcileNoInventoryAlerts).to receive(:new).with(
      contain_exactly(
        [product_one.id, store_one.id],
        [product_two.id, store_two.id],
        [product_three.id, store_three.id]
      )
    ).once.and_return(reconciler)
    expect(reconciler).to receive(:call).once

    described_class.new(Rails.root.join('spec/fixtures/files/test_tracking_events.csv')).call
  end

  it 'rolls back the import if ReconcileNoInventoryAlerts fails - this is one atomic operation!' do
    Rails.application.load_seed

    reconciler = instance_double(InventoryTrackingEvents::ReconcileNoInventoryAlerts)
    allow(reconciler).to receive(:call).and_raise("ERROR!")
    allow(InventoryTrackingEvents::ReconcileNoInventoryAlerts)
      .to receive(:new).and_return(reconciler)

    expect {
      described_class.new(Rails.root.join('spec/fixtures/files/test_tracking_events.csv')).call
    }.to raise_error(RuntimeError, "ERROR!")

    expect(InventoryTrackingEvent.count).to eq 0 # import rolled back
  end

end
