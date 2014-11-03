module CanonicalEmails
  module Reverse
    def self.transform(value)
      Mail::Address.new(value).tap do |email|
        email.instance_eval do
          def get_local
            super.reverse
          end

          def domain
            super.reverse
          end
        end
      end
    end
  end
end
