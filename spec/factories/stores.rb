FactoryBot.define do
  factory :store do
    sequence(:address) { |n| "#{n} Example Street" }
  end
end
