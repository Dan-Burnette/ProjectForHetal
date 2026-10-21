RSpec.shared_examples 'a trackable event' do |measurement_attributes|
  let(:brand) { Brand.create!(name: 'Example Brand') }
  let(:product) { Product.create!(name: 'Example Product', brand: brand) }
  let(:store) { Store.create!(address: '123 Main Street') }
  let(:attributes) do
    {
      product: product,
      store: store,
      event_time: Time.zone.parse('2026-10-17 11:00')
    }.merge(measurement_attributes)
  end

  describe '.by_recency' do
    it 'orders by event_time newest first, regardless of insertion order' do
      middle = described_class.create!(attributes)
      newest = described_class.create!(attributes.merge(event_time: Time.zone.parse('2026-10-17 12:00')))
      oldest = described_class.create!(attributes.merge(event_time: Time.zone.parse('2026-10-17 10:00')))

      expect(described_class.by_recency.to_a).to eq([newest, middle, oldest])
      expect(described_class.by_recency.first).to eq(newest)
    end
  end

  it 'requires product' do
    event = described_class.new(attributes.merge(product: nil))

    expect(event).not_to be_valid
    expect(event.errors[:product]).to be_present
  end

  it 'requires store' do
    event = described_class.new(attributes.merge(store: nil))

    expect(event).not_to be_valid
    expect(event.errors[:store]).to be_present
  end

  it 'requires event_time' do
    event = described_class.new(attributes.merge(event_time: nil))

    expect(event).not_to be_valid
    expect(event.errors[:event_time]).to be_present
  end
end
