# frozen_string_literal: true

module CanonicalEmails
  # An unchanged Mail address with original local-part metadata.
  class Address < Mail::Address
    attr_reader :username, :tag

    def self.transform(value)
      new(value)
    end

    def initialize(value = nil)
      super
      update_properties
    end

    def address=(value)
      super
      update_properties
    end

    private

    def normalize?
      true
    end

    def update_properties
      @username = get_local
      @tag = nil
    end
  end
end
