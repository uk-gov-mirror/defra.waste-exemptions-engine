# frozen_string_literal: true

require "rails_helper"

module WasteExemptionsEngine
  RSpec.describe TransientRegistration, type: :model do
    describe "#workflow_state" do
      it_behaves_like "a simple bidirectional transition",
                      previous_state: :exemptions_form,
                      current_state: :check_your_answers_form,
                      next_state: :declaration_form
    end
  end
end