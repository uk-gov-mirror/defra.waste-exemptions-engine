# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe RegistrationPendingBankTransferLetterService do
    describe "run" do
      subject(:run_service) { described_class.run(registration:) }

      # Make sure it's a real postcode for Notify validation purposes
      let(:address) { create(:address, :postal, postcode: "BS1 1AA") }
      let(:registration) { create(:registration, :complete, :with_active_exemptions, account: build(:account)) }
      let(:breakdown) { "* U1 Using waste in construction: £435.96" }
      let(:breakdown_presenter) { instance_double(ChargeBreakdownPresenter, breakdown:) }
      let(:notifications_client) { instance_double(Notifications::Client, send_letter: nil) }

      before do
        registration.contact_address = address
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
            reg_identifier: registration.reference,
            exemption_breakdown: breakdown,
            "address_line_1" => "#{registration.contact_first_name} #{registration.contact_last_name}",
            "address_line_6" => "BS1 1AA"
          )
        )
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
