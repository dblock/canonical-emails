# frozen_string_literal: true

module CanonicalEmails
  # Removes periods and plus tags and normalizes case for gmail.com addresses only.
  module GMail
    # A Gmail-aware address that retains the original username and plus-tag.
    class Address < Mail::Address
      attr_reader :username, :tag

      def initialize(value = nil)
        super
        update_properties
      end

      def address=(value)
        super
        update_properties
      end

      def local(*)
        value = super
        return value unless value && gmail?

        value.split('+', 2).first.delete('.').downcase
      end

      def domain(*)
        value = super
        value&.casecmp?('gmail.com') ? value.downcase : value
      end

      private

      def gmail?
        domain&.casecmp?('gmail.com')
      end

      def update_properties
        @username = get_local
        @tag = username && gmail? ? username.split('+', 2).at(1) : nil
      end
    end

    def self.transform(value)
      Address.new(value)
    end
  end
end
