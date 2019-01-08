# frozen_string_literal: true

module WasteExemptionsEngine
  class RegistrationExemption < ActiveRecord::Base
    include CanChangeExemptionStatus

    self.table_name = "registration_exemptions"

    belongs_to :registration
    belongs_to :exemption

  end
end