# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe ProofOfPaymentPresenter do
    subject(:personalisation) { described_class.new(registration:).personalisation }

    let(:registration) do
      instance_double(Registration,
                      reference: "WEX123456",
                      contact_first_name: "Jo",
                      contact_last_name: "Bloggs",
                      submitted_at: Date.new(2026, 9, 1),
                      account:)
    end
    let(:account) { instance_double(Account, payments: [payment], orders: [order]) }
    let(:order) do
      instance_double(Order,
                      id: 1,
                      exemptions:,
                      bucket:,
                      charge_detail:)
    end
    let(:exemptions) { [exemption] }
    let(:bucket) { nil }
    let(:payment) do
      instance_double(Payment,
                      success?: true,
                      payment_type: Payment::PAYMENT_TYPE_GOVPAY,
                      payment_amount: 49_500,
                      date_time: Time.zone.local(2026, 9, 2, 12),
                      created_at: Time.zone.local(2026, 9, 2, 12),
                      id: 1)
    end
    let(:exemption) do
      instance_double(Exemption,
                      code: "U1",
                      summary: "using waste in construction",
                      band_id: 1)
    end
    let(:band_charge_detail) do
      instance_double(BandChargeDetail,
                      band_id: 1,
                      initial_compliance_charge_amount: 43_596,
                      additional_compliance_charge_amount: 0)
    end
    let(:charge_detail) do
      instance_double(ChargeDetail,
                      registration_charge_amount: 5904,
                      bucket_charge_amount: 0,
                      band_charge_details: [band_charge_detail])
    end
    let(:expected_breakdown) do
      "* U1 Using waste in construction: £435.96\n" \
        "* Registration charge: £59.04\n" \
        "* VAT exempt: £0"
    end

    def expected_personalisation
      {
        reg_identifier: "WEX123456",
        first_name: "Jo",
        last_name: "Bloggs",
        date_registered: "1 September 2026",
        date_paid: "2 September 2026",
        payment_method: "Card",
        payment_amount: "495.00",
        exemption_breakdown: expected_breakdown
      }
    end

    it "provides the Notify template values" do
      expect(personalisation).to eq(expected_personalisation)
    end

    context "with a BACS payment" do
      before do
        allow(payment).to receive(:payment_type).and_return(Payment::PAYMENT_TYPE_BANK_TRANSFER)
      end

      it "labels the payment method as BACS" do
        expect(personalisation[:payment_method]).to eq("BACS")
      end
    end

    context "with multiple successful payments" do
      before do
        latest_payment = instance_double(Payment,
                                         success?: true,
                                         payment_type: Payment::PAYMENT_TYPE_BANK_TRANSFER,
                                         payment_amount: 10_000,
                                         date_time: Time.zone.local(2026, 9, 3, 12),
                                         created_at: Time.zone.local(2026, 9, 3, 12),
                                         id: 2)
        allow(account).to receive(:payments).and_return([payment, latest_payment])
      end

      it "shows the total paid and details of the latest payment" do
        expect(personalisation).to include(
          payment_amount: "595.00",
          payment_method: "BACS",
          date_paid: "3 September 2026"
        )
      end
    end

    context "with an unsuccessful payment after the successful payment" do
      before do
        failed_payment = instance_double(Payment,
                                         success?: false,
                                         payment_type: Payment::PAYMENT_TYPE_BANK_TRANSFER,
                                         payment_amount: 10_000,
                                         date_time: Time.zone.local(2026, 9, 3, 12),
                                         created_at: Time.zone.local(2026, 9, 3, 12),
                                         id: 2)
        allow(account).to receive(:payments).and_return([payment, failed_payment])
      end

      it "excludes the unsuccessful payment" do
        expect(personalisation).to include(
          payment_amount: "495.00",
          payment_method: "Card",
          date_paid: "2 September 2026"
        )
      end
    end

    context "with a successful refund" do
      before do
        refund = instance_double(Payment,
                                 success?: true,
                                 payment_type: Payment::PAYMENT_TYPE_REFUND,
                                 payment_amount: -500,
                                 date_time: Time.zone.local(2026, 9, 3, 12),
                                 created_at: Time.zone.local(2026, 9, 3, 12),
                                 id: 2)
        allow(account).to receive(:payments).and_return([payment, refund])
      end

      it "shows the net amount while retaining the latest positive payment details" do
        expect(personalisation).to include(
          payment_amount: "490.00",
          payment_method: "Card",
          date_paid: "2 September 2026"
        )
      end
    end

    context "when the payment date is not recorded" do
      before { allow(payment).to receive(:date_time).and_return(nil) }

      it "uses the payment creation date" do
        expect(personalisation[:date_paid]).to eq("2 September 2026")
      end
    end

  end
end
