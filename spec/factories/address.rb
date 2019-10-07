# frozen_string_literal: true

FactoryBot.define do
  address_types = WasteExemptionsEngine::Address.address_types
  modes = WasteExemptionsEngine::Address.modes

  factory :address, class: WasteExemptionsEngine::Address do
    trait :operator_address do
      address_type { address_types[:operator] }
    end

    trait :contact_address do
      address_type { address_types[:contact] }
    end

    trait :site_address do
      address_type { address_types[:site] }
    end

    trait :site_using_grid_reference do
      site_address
      description { Faker::Lorem.sentence }
      grid_reference { "ST 58337 72855" }
    end

    trait :postal do
      manual

      sequence :postcode do |n|
        "BS#{n}AA"
      end

      uprn { Faker::Alphanumeric.unique.alphanumeric(number: 8) }
      premises { Faker::Address.community }
      street_address { Faker::Address.street_address }
      locality { Faker::Address.country }
      city { Faker::Address.city }
    end

    trait :manual do
      mode { modes[:manual] }
    end

    trait :lookup do
      mode { modes[:lookup] }
    end

    trait :auto do
      mode { modes[:auto] }
    end
  end
end
