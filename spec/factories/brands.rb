FactoryBot.define do
  factory :brand do
    sequence(:name) { |n| "Example Brand #{n}" }
  end
end
