# frozen_string_literal: true

module CanonicalEmails
  # Removes periods and plus tags and normalizes case for gmail.com addresses only.
  class GMail < Address
    include Behaviors::DowncaseLocal
    include Behaviors::DowncaseDomain
    include Behaviors::RemovePeriods
    include Behaviors::StripTags

    def self.accepts?(domain)
      domain&.casecmp?('gmail.com')
    end
  end
end
