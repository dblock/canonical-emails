# frozen_string_literal: true

module CanonicalEmails
  # Removes insignificant dots and normalizes case for gmail.com addresses only.
  module GMail
    def self.transform(value)
      Mail::Address.new(value).tap do |email|
        if value && email.domain && ['gmail.com'].include?(email.domain.downcase)
          email.instance_eval do
            def get_local
              value = super
              value&.gsub('.', '')&.downcase
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
end
