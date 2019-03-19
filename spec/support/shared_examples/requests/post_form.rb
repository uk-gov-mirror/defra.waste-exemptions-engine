# frozen_string_literal: true

RSpec.shared_examples "POST form" do |form_factory, path, empty_form_is_valid = false|
  let(:correct_form) { build(form_factory) }
  let(:incorrect_workflow_state) { Helpers::WorkflowStates.previous_state(correct_form.transient_registration) }
  let(:incorrect_form) { build(incorrect_workflow_state) }
  let(:post_request_path) { "/waste_exemptions_engine#{path}" }
  let(:form_data) { { override_me: "Set :form_data in the calling spec." } }

  describe "POST #{form_factory}" do
    context "when the form is not valid", unless: empty_form_is_valid do
      let(:empty_form_request_body) { { form_factory => { token: correct_form.token } } }

      it "renders the same template" do
        post post_request_path, empty_form_request_body
        expect(response).to render_template("waste_exemptions_engine/#{form_factory}s/new")
      end

      it "responds to the POST request with a 200 status code" do
        post post_request_path, empty_form_request_body
        expect(response.code).to eq("200")
      end
    end

    context "when the token has been modified" do
      let(:modified_token_request_body) { { form_factory => form_data.merge(token: "modified-token") } }
      status_code = WasteExemptionsEngine::ApplicationController::UNSUCCESSFUL_REDIRECTION_CODE

      it "renders the start form" do
        post post_request_path, modified_token_request_body
        expect(response.location).to include("/waste_exemptions_engine/start/")
      end

      it "responds to the POST request with a #{status_code} status code" do
        post post_request_path, modified_token_request_body
        expect(response.code).to eq(status_code.to_s)
      end
    end

    context "when the registration is in the correct state" do
      let(:good_request_body) { { form_factory => form_data.merge(token: correct_form.token) } }
      status_code = WasteExemptionsEngine::ApplicationController::SUCCESSFUL_REDIRECTION_CODE

      # A successful POST request redirects to the next form in the work flow. We have chosen to
      # differentiate 'good' rediection as 303 and 'bad' redirection as 302.
      # If this test fails for a given form because the status is 200 instead of 303 it is most
      # likely because the form object is not valid.
      it "responds to the POST request with a #{status_code} status code" do
        post post_request_path, good_request_body
        expect(response.code).to eq(status_code.to_s)
      end
    end

    context "when the registration is not in the correct state" do
      let(:bad_request_body) { { form_factory => form_data.merge(token: incorrect_form.token) } }
      let(:bad_request_redirection_path) do
        workflow_path = "new_#{incorrect_form.transient_registration.workflow_state}_path".to_sym
        send(workflow_path, incorrect_form.transient_registration.token)
      end
      status_code = WasteExemptionsEngine::ApplicationController::UNSUCCESSFUL_REDIRECTION_CODE

      it "renders the appropriate template" do
        post post_request_path, bad_request_body
        expect(response.location).to include(bad_request_redirection_path)
      end

      it "responds to the POST request with a 302 status code" do
        post post_request_path, bad_request_body
        expect(response.code).to eq(status_code.to_s)
      end

      it "does not update the transient registration workflow state" do
        # Start with a fresh form since incorrect_form could already have an updated workflow state
        trans_reg_id = incorrect_form.transient_registration.id
        expect(WasteExemptionsEngine::TransientRegistration.find(trans_reg_id).workflow_state).to eq(incorrect_workflow_state.to_s)
        post post_request_path, bad_request_body
        expect(WasteExemptionsEngine::TransientRegistration.find(trans_reg_id).workflow_state).to eq(incorrect_workflow_state.to_s)
      end
    end
  end
end