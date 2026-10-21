FactoryBot.define do
  factory :no_inventory_alert do
    product
    store
    failed_checks { 2 }
    first_failure_at { Time.current - 1.hour }
    last_failure_at { first_failure_at + 1.hour }
  end
end
