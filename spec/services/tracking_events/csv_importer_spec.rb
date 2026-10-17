require 'rails_helper'
require 'tempfile'

RSpec.describe TrackingEvents::CsvImporter do
  describe '#call' do

    context 'when given a CSV without the expected headers' do
      it "raises an error when any *one* header is missing" do
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

      it 'raises an error when *multiple* headers are missing' do
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
  end
end
