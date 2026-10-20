# frozen_string_literal: true

module CanonicalEmails
  # Normalizes the local part and domain without changing the display name.
  module Downcase
    # Lowercases both parts without provider-specific transformations.
    class Address < CanonicalEmails::Address
      include Behaviors::DowncaseLocal
      include Behaviors::DowncaseDomain
    end

    def self.transform(value)
      return unless value

      Address.new(value)
    end
  end
end
