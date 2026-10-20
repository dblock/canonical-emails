# frozen_string_literal: true

module CanonicalEmails
  # Opt-in transformations for Address subclasses.
  module Behaviors
    # Lowercases the local part.
    module DowncaseLocal
      def local(*)
        super&.downcase
      end
    end

    # Lowercases the domain.
    module DowncaseDomain
      def domain(*)
        super&.downcase
      end
    end

    # Removes periods from the local part.
    module RemovePeriods
      def local(*)
        super&.delete('.')
      end
    end

    # Removes the plus suffix while retaining it in the tag property.
    module StripTags
      def local(*)
        value = super
        return unless value

        value.split('+', 2).first
      end

      private

      def update_properties
        super
        @tag = username.split('+', 2).at(1) if username
      end
    end
  end
end
