# frozen_string_literal: true

module WasteExemptionsEngine
  class Registration < ActiveRecord::Base
    include CanChangeWorkflowStatus

    self.table_name = "registrations"

    # We want to create the interim record at the same time as the registration
    # is initialized. With activerecord objects overriding the initializer is
    # seen as an anti-pattern, so instead we rely on its callbacks.
    after_create :create_interim, :apply_reference

    # HasSecureToken provides an easy way to generate unique random tokens for
    # any model in ruby on rails. We use it to uniquely identify an registration
    # by something other than it's db ID, or its reference number. We can then
    # use token instead of ID to identify an registration during the journey. The
    # format makes it sufficiently hard for another user to attempt to 'guess'
    # the token of another registration in order to see its details.
    # See https://github.com/robertomiranda/has_secure_token
    has_secure_token
    validates_presence_of :token, on: :save

    has_one :interim, autosave: true
    has_many :addresses
    has_many :registration_exemptions
    has_many :exemptions, through: :registration_exemptions

    # Some business types should not have a company_no
    def company_no_required?
      %w[limitedCompany limitedLiabilityPartnership].include?(business_type)
    end

    def operator_address
      find_address_by_type(Address.address_types[:operator])
    end

    def contact_address
      find_address_by_type(Address.address_types[:contact])
    end

    def site_address
      find_address_by_type(Address.address_types[:site])
    end

    private

    def find_address_by_type(address_type)
      return nil unless addresses.present?

      addresses.where(address_type: address_type).first
    end

    def apply_reference
      self.reference = format("WEX%06d", id)
      save!
    end
  end
end