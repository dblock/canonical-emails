# frozen_string_literal: true

module CanonicalEmails
  # Adds lazily evaluated canonical address accessors to application models.
  module Extensions
    extend ActiveSupport::Concern

    # Defines provider-aware canonical address accessors.
    module ClassMethods
      def canonical_email(field, type: nil, as: :"canonical_#{field}")
        raise ArgumentError, 'as must be a nonempty String or Symbol' unless (as.is_a?(String) || as.is_a?(Symbol)) && !as.to_s.empty?

        if as.to_s == field.to_s
          @canonical_email_readers ||= Module.new.tap { |readers| prepend readers }
          @canonical_email_readers.define_method(as) do
            CanonicalEmails.parse(super(), type: type)
          end
        else
          define_method as do
            CanonicalEmails.parse(send(field), type: type)
          end
        end
      end
    end
  end
end
