# frozen_string_literal: true

module CanonicalEmails
  # Opt-in transformations for Address subclasses.
  module Behaviors
    # Lowercases the local part.
    module DowncaseLocal
      def local(*)
        value = super
        normalize? ? value&.downcase : value
      end
    end

    # Lowercases the domain.
    module DowncaseDomain
      def domain(*)
        value = super
        normalize? ? value&.downcase : value
      end
    end

    # Removes periods from the local part.
    module RemovePeriods
      def local(*)
        value = super
        normalize? ? value&.delete('.') : value
      end
    end

    # Removes the plus suffix while retaining it in the tag property.
    module StripTags
      def local(*)
        value = super
        return value unless value && normalize?

        value.split('+', 2).first
      end

      private

      def update_properties
        super
        @tag = username && normalize? ? username.split('+', 2).at(1) : nil
      end
    end
  end
end
