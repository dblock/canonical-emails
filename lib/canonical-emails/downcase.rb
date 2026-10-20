# frozen_string_literal: true

module CanonicalEmails
  # Normalizes the local part and domain without changing the display name.
  class Downcase < Address
    include Behaviors::DowncaseLocal
    include Behaviors::DowncaseDomain
  end
end
