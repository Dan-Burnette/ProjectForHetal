require 'rails_helper'
require_relative '../../support/factory_bot'

RSpec.describe InventoryTrackingEvents::NoInventoryStreaksQuery do
  let(:product) { create(:product) }
  let(:store) { create(:store) }
  let(:product_store_pairs) { [[product.id, store.id]] }
  let(:start_time) { Time.zone.parse('2026-10-01 12:00:00') }

  def check(inventory_present, at:, product:, store:)
    create(:inventory_tracking_event, product: product, store: store,
           inventory_present: inventory_present, event_time: at)
  end

  it 'does not count single failed inventory checks' do
    check(false, at: start_time, product: product, store: store)
    check(true, at: start_time + 1.hour, product: product, store: store)
    check(false, at: start_time + 2.hours, product: product, store: store)

    streaks = described_class.new(product_store_pairs).call

    expect(streaks).to be_empty
  end

  it 'returns completed and ongoing failure streaks' do
    check(true, at: start_time, product: product, store: store)

    streak_one_first_fail = check(false, at: start_time + 1.hour, product: product, store: store)
    streak_one_middle_fail = check(false, at: start_time + 2.hour, product: product, store: store)
    streak_one_last_fail = check(false, at: start_time + 3.hour, product: product, store: store)
    check(true, at: start_time + 4.hours, product: product, store: store)

    streak_two_first_fail = check(false, at: start_time + 5.hours, product: product, store: store)
    streak_two_middle_fail = check(false, at: start_time + 6.hours, product: product, store: store)
    streak_two_last_fail = check(false, at: start_time + 7.hours, product: product, store: store)

    streaks = described_class.new(product_store_pairs).call

    expect(streaks).to eq([
      {
        product_id: product.id, store_id: store.id, failed_checks: 3,
        first_failure_at: streak_one_first_fail.event_time,
        last_failure_at: streak_one_last_fail.event_time
      },
      {
        product_id: product.id, store_id: store.id, failed_checks: 3,
        first_failure_at: streak_two_first_fail.event_time,
        last_failure_at: streak_two_last_fail.event_time
      }
    ])
  end

  it 'determines first & last failure times with event_time order rather than insertion order' do
    last = check(false, at: start_time + 2.hours, product: product, store: store)
    first = check(false, at: start_time, product: product, store: store)
    middle = check(false, at: start_time + 1.hour, product: product, store: store)

    streaks = described_class.new(product_store_pairs).call

    expect(streaks).to eq([
      {
        product_id: product.id,
        store_id: store.id,
        failed_checks: 3,
        first_failure_at: first.event_time,
        last_failure_at: last.event_time
      }
    ])
  end

  it 'keeps each requested product/store history separate' do
    other_product = create(:product)
    other_store = create(:store)
    product_store_pairs =[
      [product.id, store.id],
      [product.id, other_store.id],
      [other_product.id, other_store.id],
    ]

    combination_one_first_fail =
      check(false, at: start_time + 1.hours, product: product, store: store)
    combination_one_last_fail =
      check(false, at: start_time + 2.hours, product: product, store: store)

    combination_two_first_fail =
      check(false, at: start_time + 1.hours, product: product, store: other_store)
    combination_two_last_fail =
      check(false, at: start_time + 2.hours, product: product, store: other_store)

    combination_three_first_fail =
      check(false, at: start_time + 1.hours, product: other_product, store: other_store)
    combination_three_last_fail =
      check(false, at: start_time + 2.hours, product: other_product, store: other_store)

    streaks = described_class.new(product_store_pairs).call

    expect(streaks).to include(
      {
        product_id: product.id, store_id: store.id, failed_checks: 2,
        first_failure_at: combination_one_first_fail.event_time,
        last_failure_at: combination_one_last_fail.event_time
      },
      {
        product_id: product.id, store_id: other_store.id, failed_checks: 2,
        first_failure_at: combination_two_first_fail.event_time,
        last_failure_at: combination_two_last_fail.event_time
      },
      {
        product_id: other_product.id, store_id: other_store.id, failed_checks: 2,
        first_failure_at: combination_three_first_fail.event_time,
        last_failure_at: combination_three_last_fail.event_time
      }
    )
  end

  it 'returns no streaks when no pairs are requested' do
    check(false, at: start_time, product: product, store: store)
    check(false, at: start_time + 1.hour, product: product, store: store)

    streaks = described_class.new([]).call

    expect(streaks).to eq([])
  end

  it 'returns no streaks when the requested pair has no events' do
    streaks = described_class.new(product_store_pairs).call

    expect(streaks).to eq([])
  end

  it 'returns no streaks when there are no failure streaks' do
    check(false, at: start_time, product: product, store: store)
    check(true, at: start_time + 1.hour, product: product, store: store)

    streaks = described_class.new(product_store_pairs).call

    expect(streaks).to eq([])
  end

end
