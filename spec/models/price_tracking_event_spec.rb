require 'rails_helper'
require_relative '../support/shared_examples/trackable_event'

RSpec.describe PriceTrackingEvent, type: :model do
  it_behaves_like 'a trackable event', { price: '1.20' }
end
