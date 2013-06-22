module CanonicalEmails
  module Downcase

    def self.transform(value)
      Mail::Address.new(value).tap do |email|
        email.instance_eval do
          def get_local
            value = super
            value.downcase if value
          end
          def domain
            value = super
            value.downcase if value
          end
        end
      end if value
    end

  end
end