require 'rails_helper'
require 'tempfile'

RSpec.describe TrackingEvents::CsvImporter do
  it 'successfully imports test_tracking_events.csv (a shorter, 3 row representative csv)' do
    Rails.application.load_seed

    expect do
      described_class.new(Rails.root.join('spec/fixtures/files/test_tracking_events.csv')).call
    end.to change(TrackingEvent, :count).by(3)

    first = TrackingEvent.first
    expect(first.store.address).to eq "18 Salamandastron Beach Road, Western Shores"
    expect(first.product.name).to eq "Paleo-DNA Sequencing Devices"
    expect(first.event_time).to eq Date.parse("2025-01-02")
    expect(first.inventory_present).to eq true

    second = TrackingEvent.second
    expect(second.store.address).to eq "135 Strickland Propane Road, Arlen, Texas"
    expect(second.product.name).to eq "Nobleman’s Wine Reserve"
    expect(second.event_time).to eq Date.parse("2025-09-16")
    expect(second.inventory_present).to eq true

    third = TrackingEvent.third
    expect(third.store.address).to eq "6 Kandra Alley, Fadrex City"
    expect(third.product.name).to eq "Abbey October Ale"
    expect(third.event_time).to eq Date.parse("2025-10-07")
    expect(third.inventory_present).to eq false
  end

  context 'when given a CSV without the expected headers' do
    it "raises error when *one* header is missing" do
      described_class::REQUIRED_HEADERS.each do |missing_header|
        headers = described_class::REQUIRED_HEADERS - [missing_header]

        Tempfile.create(['tracking_events', '.csv']) do |file|
          file.write(CSV.generate_line(headers))
          file.flush

          expect { described_class.new(file.path).call }.to raise_error(
            ArgumentError,
            "CSV is missing required columns: #{missing_header}"
          )
        end
      end
    end

    it 'raises error when *multiple* headers are missing' do
      Tempfile.create(['tracking_events', '.csv']) do |file|
        file.write("Address,Product Name\n123 Main Street,Example Product\n")
        file.flush

        expect { described_class.new(file.path).call }.to raise_error(
          ArgumentError,
          'CSV is missing required columns: Date, Inventory Present'
        )
      end
    end
  end

  it 'raises an error for an unhandled/unexpected Inventory Present value' do
    store = Store.create!(address: '123 Main Street')
    brand = Brand.create!(name: 'Example Brand')
    product = Product.create!(name: 'Example Product', brand: brand)

    Tempfile.create(['tracking_events', '.csv']) do |file|
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

  it 'raises error when date is not parseable' do
    store = Store.create!(address: '123 Main Street')
    brand = Brand.create!(name: 'Example Brand')
    product = Product.create!(name: 'Example Product', brand: brand)

    Tempfile.create(['tracking_events', '.csv']) do |file|
      file.write(CSV.generate_line(described_class::REQUIRED_HEADERS))
      file.write(CSV.generate_line([store.address, product.name, 'invalid-date', 'True']))
      file.flush

      expect { described_class.new(file.path).call }.to raise_error(Date::Error)
    end
  end
end
