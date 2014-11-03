module CanonicalEmails
  module GMail
    def self.transform(value)
      Mail::Address.new(value).tap do |email|
        if email.domain && ['gmail.com'].include?(email.domain.downcase)
          email.instance_eval do
            def get_local
              value = super
              value.gsub('.', '').downcase if value
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
end
