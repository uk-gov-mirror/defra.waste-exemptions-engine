# frozen_string_literal: true

require "notifications/client"

module WasteExemptionsEngine
  class RegistrationPendingBankTransferEmailService < BaseService
    include CanHaveCommunicationLog
    include FinanceDetailsHelper

    def run(registration:, recipient:)
      return unless registration.account.present?

      @registration = registration
      @recipient = recipient

      client = Notifications::Client.new(WasteExemptionsEngine.configuration.notify_api_key)

      result = client.send_email(options)

      create_log(registration:, notify_response: result)

      result
    end

    # For CanHaveCommunicationLog
    def communications_log_params
      {
        message_type: "email",
        template_id: template_id,
        template_label: "Breakdown of charges email",
        sent_to: @recipient
      }
    end

    private

    def template_id
      NotificationTemplates::BREAKDOWN_OF_CHARGES_EMAIL
    end

    def options
      payment_details_path = "waste_exemptions_engine.registration_received_pending_payment_forms.new"
      {
        email_address: @recipient,
        template_id: template_id,
        personalisation: {
          first_name: @registration.contact_first_name,
          last_name: @registration.contact_last_name,
          account_number: I18n.t("#{payment_details_path}.account_number_value"),
          sort_code: I18n.t("#{payment_details_path}.sort_code_value"),
          payment_due: payment_due,
          iban: I18n.t("#{payment_details_path}.iban_value"),
          swiftbic: I18n.t("#{payment_details_path}.swift_bic_value"),
          currency: I18n.t("#{payment_details_path}.currency_value"),
          reg_identifier: @registration.reference,
          date_registered: @registration.submitted_at.to_date.to_fs(:day_month_year),
          exemption_breakdown: ChargeBreakdownPresenter.new(registration: @registration).breakdown
        }
      }
    end

    def payment_due
      display_pence_as_pounds_and_cents(@registration.account.balance.abs)
    end
  end
end
