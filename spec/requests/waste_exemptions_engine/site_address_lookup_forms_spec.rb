# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe "Site Address Lookup Forms", type: :request, vcr: true do
    before(:each) { VCR.insert_cassette("postcode_valid", allow_playback_repeats: true) }
    after(:each) { VCR.eject_cassette }

    include_examples "GET form", :site_address_lookup_form, "/site-address-lookup"
    include_examples "go back", :site_address_lookup_form, "/site-address-lookup/back"
    include_examples "POST form", :site_address_lookup_form, "/site-address-lookup" do
      let(:form_data) { { temp_address: "340116" } }
    end

    include_examples "skip to manual address",
                     :site_address_lookup_form,
                     request_path: "/site-address-lookup/skip_to_manual_address",
                     result_path: "/site-address-manual"
  end
end