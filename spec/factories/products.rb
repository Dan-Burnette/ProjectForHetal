FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Example Product #{n}" }
    brand
  end
end
