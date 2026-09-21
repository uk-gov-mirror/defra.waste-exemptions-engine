# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe ChargeBreakdownPresenter do
    subject(:breakdown) { described_class.new(registration:).breakdown }

    let(:registration) { instance_double(Registration, account:) }
    let(:account) { instance_double(Account, orders: [order]) }
    let(:order) { instance_double(Order, exemptions:, bucket:, charge_detail:) }
    let(:exemptions) { [exemption] }
    let(:bucket) { nil }
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

    it "formats the stored exemption and registration charges" do
      expect(breakdown).to eq(
        "* U1 Using waste in construction: £435.96\n" \
        "* Registration charge: £59.04\n" \
        "* VAT exempt: £0"
      )
    end

    context "with multiple exemptions in the same band" do
      let(:exemptions) do
        [
          exemption,
          instance_double(Exemption,
                          code: "U10",
                          summary: "spreading waste to benefit agricultural land",
                          band_id: 1)
        ]
      end
      let(:band_charge_detail) do
        instance_double(BandChargeDetail,
                        band_id: 1,
                        initial_compliance_charge_amount: 43_596,
                        additional_compliance_charge_amount: 7889)
      end

      it "uses the stored initial and additional charges" do
        expect(breakdown).to eq(
          "* U1 Using waste in construction: £435.96\n" \
          "* U10 Spreading waste to benefit agricultural land: £78.89\n" \
          "* Registration charge: £59.04\n" \
          "* VAT exempt: £0"
        )
      end
    end

    context "with farming exemptions" do
      let(:bucket) { instance_double(Bucket, exemptions:) }
      let(:charge_detail) do
        instance_double(ChargeDetail,
                        registration_charge_amount: 5904,
                        bucket_charge_amount: 31_114,
                        band_charge_details: [band_charge_detail])
      end

      it "shows the stored bucket charge once" do
        expect(breakdown).to eq(
          "* Farming exemptions (U1): £311.14\n" \
          "* Registration charge: £59.04\n" \
          "* VAT exempt: £0"
        )
      end
    end
  end
end
