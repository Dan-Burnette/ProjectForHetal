require 'rails_helper'
require_relative '../../support/factory_bot'

RSpec.describe InventoryTrackingEvents::ReconcileNoInventoryAlerts do
  let(:product) { create(:product) }
  let(:store) { create(:store) }
  let(:start_time) { Time.zone.parse('2026-10-01 12:00:00') }

  def check(inventory_present, at:, product:, store:)
    create(:inventory_tracking_event, product: product, store: store,
           inventory_present: inventory_present, event_time: at)
  end

  it 'creates alerts for completed and ongoing no inventory streaks' do
    streak_one_failure_one = check(false, at: start_time, product: product, store: store)
    streak_one_failure_two = check(false, at: start_time + 1.hour, product: product, store: store)
    check(true, at: start_time + 2.hours, product: product, store: store)
    streak_two_failure_one = check(false, at: start_time + 3.hours, product: product, store: store)
    streak_two_failure_two = check(false, at: start_time + 4.hours, product: product, store: store)

    described_class.new([[product.id, store.id]]).call

    alerts = NoInventoryAlert.where(product: product, store: store).order(:first_failure_at)
    expect(alerts.size).to eq 2

    expect(alerts.first.failed_checks).to eq 2
    expect(alerts.first.first_failure_at).to eq streak_one_failure_one.event_time
    expect(alerts.first.last_failure_at).to eq streak_one_failure_two.event_time

    expect(alerts.second.failed_checks).to eq 2
    expect(alerts.second.first_failure_at).to eq streak_two_failure_one.event_time
    expect(alerts.second.last_failure_at).to eq streak_two_failure_two.event_time
  end

  it 'deletes existing alerts and recreates them with new data' do
    # First data import & creation of alerts
    first_failure = check(false, at: start_time + 1.hour, product: product, store: store)
    second_failure = check(false, at: start_time + 2.hours, product: product, store: store)
    described_class.new([[product.id, store.id]]).call
    original_alert = NoInventoryAlert.find_by(product: product, store: store)

    # Second data import - original alert is now incorrect because we extend the
    # failure streak
    third_failure = check(false, at: start_time + 3.hours, product: product, store: store)
    fourth_failure = check(false, at: start_time + 4.hours, product: product, store: store)
    described_class.new([[product.id, store.id]]).call
    new_alert = NoInventoryAlert.find_by(product: product, store: store)

    expect { original_alert.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(new_alert).to be_persisted
    expect(new_alert.failed_checks).to eq(4)
    expect(new_alert.first_failure_at).to eq(first_failure.event_time)
    expect(new_alert.last_failure_at).to eq(fourth_failure.event_time)
  end

  it 'does not reconcile alerts for product/store pairs not passed in' do
    other_store = create(:store)
    other_product = create(:product)
    existing_other_alert = create(
      :no_inventory_alert,
      store: store,
      product: product,
      failed_checks: 4,
      first_failure_at: 1.day.ago,
      last_failure_at: 1.minute.ago
    )

    described_class.new([[product.id, store.id]]).call

    expect(existing_other_alert).to be_persisted # Not deleted/rebuilt!
  end

  it 'is transaction wrapped (rolls back to keep existing alerts if reconciliation fails)' do
    existing_alert = create(
      :no_inventory_alert,
      store: store,
      product: product,
      failed_checks: 2,
      first_failure_at: 1.day.ago,
      last_failure_at: 1.minute.ago
    )
    allow(NoInventoryAlert).to receive(:insert_all!).and_raise("some_error!")

    expect {
      described_class.new([[product.id, store.id]]).call
    }.to raise_error(RuntimeError, "some_error!")
    expect(existing_alert.reload).to be_persisted
  end
end
