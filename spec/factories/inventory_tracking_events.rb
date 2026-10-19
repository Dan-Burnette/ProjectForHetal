FactoryBot.define do
  factory :inventory_tracking_event do
    product
    store
    event_time { Time.current }
    inventory_present { true }

    trait :no_inventory do
      inventory_present { false }
    end
  end
end
