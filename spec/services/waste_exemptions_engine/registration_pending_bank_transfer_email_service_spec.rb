# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe RegistrationPendingBankTransferEmailService do
    describe "run" do
      subject(:run_service) { described_class.run(registration:, recipient:) }

      let(:registration) { create(:registration, :complete, account: build(:account)) }
      let(:recipient) { registration.contact_email }
      let(:reference) { "WEX0123456" }
      let(:breakdown) { "* U1 Using waste in construction: £435.96" }
      let(:breakdown_presenter) { instance_double(ChargeBreakdownPresenter, breakdown:) }
      let(:notifications_client) { instance_double(Notifications::Client, send_email: nil) }

      it_behaves_like "CanHaveCommunicationLog" do
        let(:service_class) { described_class }
        let(:parameters) { { registration: registration, recipient: registration.contact_email } }
      end

      before do
        allow(registration).to receive(:reference).and_return(reference)
        allow(ChargeBreakdownPresenter).to receive(:new).with(registration:).and_return(breakdown_presenter)
        allow(Notifications::Client).to receive(:new).and_return(notifications_client)
      end

      it "sends the breakdown of charges email using the new template" do
        run_service

        expect(notifications_client).to have_received(:send_email).with(
          email_address: recipient,
          template_id: NotificationTemplates::BREAKDOWN_OF_CHARGES_EMAIL,
          personalisation: hash_including(
            reg_identifier: reference,
            exemption_breakdown: breakdown
          )
        )
      end

      it "records the communication against the new template" do
        aggregate_failures do
          expect { run_service }.to change(CommunicationLog, :count).by(1)

          expect(registration.communication_logs.last).to have_attributes(
            message_type: "email",
            template_id: NotificationTemplates::BREAKDOWN_OF_CHARGES_EMAIL,
            template_label: "Breakdown of charges email",
            sent_to: recipient
          )
        end
      end
    end
  end
end
