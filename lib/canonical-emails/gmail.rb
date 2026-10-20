# frozen_string_literal: true

module CanonicalEmails
  # Removes periods and plus tags and normalizes case for gmail.com addresses only.
  class GMail < TaggedGMail
    include Behaviors::StripTags
  end
end
