# frozen_string_literal: true

module CanonicalEmails
  # Normalizes Gmail periods and case while retaining plus-tags.
  class TaggedGMail < Address
    include Behaviors::DowncaseLocal
    include Behaviors::DowncaseDomain
    include Behaviors::RemovePeriods

    def self.accepts?(domain)
      domain&.casecmp?('gmail.com')
    end
  end
end
