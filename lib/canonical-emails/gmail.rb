# frozen_string_literal: true

module CanonicalEmails
  # Removes periods and plus tags and normalizes case for gmail.com addresses only.
  module GMail
    # A Gmail-aware address that retains the original username and plus-tag.
    class Address < CanonicalEmails::Address
      include Behaviors::DowncaseLocal
      include Behaviors::DowncaseDomain
      include Behaviors::RemovePeriods
      include Behaviors::StripTags

      private

      def normalize?
        get_domain&.casecmp?('gmail.com')
      end
    end

    def self.transform(value)
      Address.new(value)
    end
  end
end
