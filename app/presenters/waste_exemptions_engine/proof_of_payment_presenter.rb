# frozen_string_literal: true

module WasteExemptionsEngine
  class ProofOfPaymentPresenter
    def initialize(registration:)
      @registration = registration
    end

    def personalisation
      {
        reg_identifier: registration.reference,
        first_name: registration.contact_first_name,
        last_name: registration.contact_last_name,
        date_registered: registration.submitted_at.to_date.to_fs(:day_month_year),
        date_paid: payment_date.to_date.to_fs(:day_month_year),
        payment_method: translate("payment_methods.#{latest_payment.payment_type}",
                                  default: latest_payment.payment_type.humanize),
        payment_amount: formatted_payment_amount,
        exemption_breakdown: ChargeBreakdownPresenter.new(registration:).breakdown
      }
    end

    private

    attr_reader :registration

    def successful_payments
      @successful_payments ||= registration.account.payments.select(&:success?)
    end

    def latest_payment
      @latest_payment ||= successful_payments
                          .select { |payment| payment.payment_amount.to_i.positive? }
                          .max_by { |payment| [payment.date_time || payment.created_at, payment.id] }
    end

    def formatted_payment_amount
      CurrencyConversionService.convert_pence_to_pounds(successful_payments.sum(&:payment_amount))
    end

    def payment_date
      latest_payment.date_time || latest_payment.created_at
    end

    def translate(key, **)
      I18n.t(key, scope: "waste_exemptions_engine.proof_of_payment", **)
    end
  end
end
