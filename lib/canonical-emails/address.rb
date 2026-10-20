# frozen_string_literal: true

module CanonicalEmails
  # An unchanged Mail address with original local-part metadata.
  class Address < Mail::Address
    attr_reader :username, :tag

    undef_method :address=

    def self.parse(value)
      CanonicalEmails.parse(value, type: self)
    end

    def self.accepts?(_domain)
      true
    end

    def initialize(value = nil)
      super
      raise ArgumentError, "#{self.class} does not support domain #{get_domain.inspect}" unless self.class.accepts?(get_domain)

      update_properties
    end

    private

    def update_properties
      @username = get_local
      @tag = nil
    end
  end
end
