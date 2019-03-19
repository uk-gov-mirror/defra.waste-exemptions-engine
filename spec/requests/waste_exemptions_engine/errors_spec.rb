# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe "Errors", type: :request do
    describe "#show" do
      %w[401 403 404 422].each do |code|
        it "renders the error_#{code} template" do
          get error_path(code)
          expect(response).to render_template("error_#{code}")
        end

        it "responds with a status of #{code}" do
          get error_path(code)
          expect(response.code).to eq(code)
        end
      end

      it "renders the generic error template when no matching error template exists" do
        get error_path("unknown")
        expect(response.code).to eq("500")
        expect(response).to render_template(:error_generic)
      end
    end
  end
end