# frozen_string_literal: true

module CanonicalEmails
  # Normalizes the local part and domain without changing the display name.
  module Downcase
    def self.transform(value)
      return unless value

      Mail::Address.new(value).tap do |email|
        email.instance_eval do
          def get_local
            value = super
            value&.downcase
          end

          def domain(*)
            value = super
            value&.downcase
          end
        end
      end
    end
  end
end
