# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe RegistrationPendingBankTransferLetterService do
    describe "run" do
      subject(:run_service) { described_class.run(registration:) }

      # Make sure it's a real postcode for Notify validation purposes
      let(:address) { create(:address, :postal, postcode: "BS1 1AA") }
      let(:registration) do
        create(:registration,
               :complete,
               :with_active_exemptions,
               account: build(:account),
               reference:,
               submitted_at: Date.new(2026, 9, 23))
      end
      let(:reference) { "WEX0123456" }
      let(:breakdown) { "* U1 Using waste in construction: £435.96" }
      let(:breakdown_presenter) { instance_double(ChargeBreakdownPresenter, breakdown:) }
      let(:notifications_client) { instance_double(Notifications::Client, send_letter: nil) }

      before do
        registration.contact_address = address
        allow(registration).to receive(:reference).and_return(reference)
        allow(ChargeBreakdownPresenter).to receive(:new).and_return(breakdown_presenter)
        allow(Notifications::Client).to receive(:new).and_return(notifications_client)
      end

      it_behaves_like "CanHaveCommunicationLog" do
        let(:service_class) { described_class }
        let(:a_registration) { create(:registration, :complete, :with_active_exemptions, account: build(:account)) }
        let(:parameters) { { registration: a_registration } }
      end

      it "sends the breakdown of charges letter using the new template and postal address" do
        run_service

        expect(notifications_client).to have_received(:send_letter).with(
          template_id: NotificationTemplates::BREAKDOWN_OF_CHARGES_LETTER,
          personalisation: hash_including(
            reg_identifier: reference,
            date_registered: "23 September 2026",
            iban: "GB23 NWBK 607080 10014411",
            swiftbic: "NWBK GB2L",
            currency: "Sterling",
            exemption_breakdown: breakdown,
            "address_line_1" => "#{registration.contact_first_name} #{registration.contact_last_name}",
            "address_line_6" => "BS1 1AA"
          )
        )
      end

      context "with the Notify API" do
        before do
          allow(Notifications::Client).to receive(:new).and_call_original
        end

        it "is accepted by the replacement template" do
          VCR.use_cassette("breakdown_of_charges_letter") do
            response = run_service

            aggregate_failures do
              expect(response).to be_a(Notifications::Client::ResponseNotification)
              expect(response.template["id"]).to eq(NotificationTemplates::BREAKDOWN_OF_CHARGES_LETTER)
              expect(response.content["subject"]).to eq("Your recent waste exemption registration")
              expect(response.content["body"]).to include(reference, breakdown)
              expect(response.content["body"]).to include("IBAN: GB23", "SWIFT / BIC: NWBK GB2L")
            end
          end
        end
      end

      it "records the communication against the new template" do
        aggregate_failures do
          expect { run_service }.to change(CommunicationLog, :count).by(1)

          expect(registration.communication_logs.last).to have_attributes(
            message_type: "letter",
            template_id: NotificationTemplates::BREAKDOWN_OF_CHARGES_LETTER,
            template_label: "Breakdown of charges letter"
          )
        end
      end
    end
  end
end
