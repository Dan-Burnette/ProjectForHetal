require 'rails_helper'
require_relative '../support/shared_examples/trackable_event'

RSpec.describe InventoryTrackingEvent, type: :model do
  it_behaves_like 'a trackable event', { inventory_present: true }
end
