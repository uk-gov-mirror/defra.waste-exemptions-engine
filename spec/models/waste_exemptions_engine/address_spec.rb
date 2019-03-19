# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe Address, type: :model do
    describe "public interface" do
      subject(:address) { build(:address) }

      associations = [:registration]

      (Helpers::ModelProperties::ADDRESS + associations).each do |property|
        it "responds to property" do
          expect(address).to respond_to(property)
        end
      end
    end

    it_behaves_like "it has PaperTrail", model_factory: :address,
                                         field: :organisation,
                                         ignored_fields: %i[blpu_state_code
                                                            logical_status_code
                                                            country_iso
                                                            postal_address_code]
  end
end