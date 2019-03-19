# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe SitePostcodeForm, type: :model do
    it_behaves_like "a postcode form", :site_postcode_form
  end
end