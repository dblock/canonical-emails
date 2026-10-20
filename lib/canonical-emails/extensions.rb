# frozen_string_literal: true

module CanonicalEmails
  # Adds lazily evaluated canonical address accessors to application models.
  module Extensions
    extend ActiveSupport::Concern

    private

    def cached_canonical_email(key, raw, type)
      @canonical_email_cache ||= {}
      cached = @canonical_email_cache[key]
      return cached.last if cached && cached.first == raw

      address = CanonicalEmails.parse(raw, type: type)
      @canonical_email_cache[key] = [raw&.dup, address]
      address
    end

    # Defines provider-aware canonical address accessors.
    module ClassMethods
      def canonical_email(field, type: nil, as: :"canonical_#{field}")
        raise ArgumentError, 'as must be a nonempty String or Symbol' unless (as.is_a?(String) || as.is_a?(Symbol)) && !as.to_s.empty?

        key = Object.new
        if as.to_s == field.to_s
          @canonical_email_readers ||= Module.new.tap { |readers| prepend readers }
          @canonical_email_readers.define_method(as) do
            cached_canonical_email(key, super(), type)
          end
        else
          define_method as do
            cached_canonical_email(key, send(field), type)
          end
        end
      end
    end
  end
end
