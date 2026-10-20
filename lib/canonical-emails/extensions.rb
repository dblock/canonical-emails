# frozen_string_literal: true

module CanonicalEmails
  # Adds lazily evaluated canonical address accessors to application models.
  module Extensions
    extend ActiveSupport::Concern

    # Defines provider-aware canonical address accessors.
    module ClassMethods
      def canonical_email(field, type: nil)
        define_method "canonical_#{field}" do
          CanonicalEmails.parse(send(field), type: type)
        end
      end
    end
  end
end
