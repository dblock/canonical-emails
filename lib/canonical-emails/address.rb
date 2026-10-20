# frozen_string_literal: true

module CanonicalEmails
  # An unchanged Mail address with original local-part metadata.
  class Address < Mail::Address
    attr_reader :username, :tag

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

    def address=(value)
      raise TypeError, 'address must be a String or nil' unless value.nil? || value.is_a?(String)

      data = Mail::Parsers::AddressListsParser.parse(value).addresses.first if value && !value.strip.empty?
      raise ArgumentError, "#{self.class} does not support domain #{data&.domain.inspect}" unless self.class.accepts?(data&.domain)

      super(data)
      @display_name = nil
      @format_comments = nil
      update_properties
    end

    private

    def update_properties
      @username = get_local
      @tag = nil
    end
  end
end
