# frozen_string_literal: true

module CanonicalEmails
  # Adds lazily evaluated canonical address accessors to application models.
  module Extensions
    extend ActiveSupport::Concern

    # Defines accessors that apply transformations in their declared order.
    module ClassMethods
      def canonical_email(field, *parsers)
        define_method "canonical_#{field}" do
          value = send(field)
          Array(parsers).each do |parser|
            value = parser.transform(value.to_s)
          end
          value
        end
      end
    end
  end
end
