# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe "Edit Complete Forms", type: :request do
    let(:form) { build(:edit_complete_form) }

    describe "GET edit_complete_form" do
      let(:request_path) { "/waste_exemptions_engine/edit-complete/#{form.token}" }

      context "when `WasteExemptionsEngine.configuration.edit_enabled` is \"true\"" do
        before(:each) do
          WasteExemptionsEngine.configuration.edit_enabled = "true"
        end

        it "renders the appropriate template" do
          get request_path
          expect(response).to render_template("waste_exemptions_engine/edit_complete_forms/new")
        end

        it "responds to the GET request with a 200 status code" do
          get request_path
          expect(response.code).to eq("200")
        end

        context "when the host application has a current_user" do
          let(:current_user) { OpenStruct.new(id: 1) }

          before do
            allow(WasteExemptionsEngine.configuration).to receive(:use_current_user_for_whodunnit).and_return(true)
            allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current_user)
          end

          it "assigns the correct whodunnit to the registration version", versioning: true do
            get request_path
            registration = WasteExemptionsEngine::Registration.where(reference: form.transient_registration.reference).first
            expect(registration.reload.versions.last.whodunnit).to eq(current_user.id.to_s)
          end
        end

        context "when the host application does not have a current_user" do
          it "assigns the correct whodunnit to the registration version", versioning: true do
            get request_path
            registration = WasteExemptionsEngine::Registration.where(reference: form.transient_registration.reference).first
            expect(registration.reload.versions.last.whodunnit).to eq("public user")
          end
        end
      end

      context "when `WasteExemptionsEngine.configuration.edit_enabled` is anything other than \"true\"" do
        before(:each) { WasteExemptionsEngine.configuration.edit_enabled = "false" }

        it "renders the error_404 template" do
          get request_path
          expect(response.location).to include("errors/404")
        end

        it "responds with a status of 404" do
          get request_path
          expect(response.code).to eq("404")
        end

        it "does not call the EditCompletionService" do
          expect(EditCompletionService).to_not receive(:run)
          get request_path
        end
      end
    end

    describe "unable to go submit GET back" do
      let(:request_path) { "/waste_exemptions_engine/edit-complete/back/#{form.token}" }
      it "raises an error" do
        expect { get request_path }.to raise_error(ActionController::RoutingError)
      end
    end

    include_examples "unable to POST form", :edit_complete_form, "/edit-complete"
  end
end