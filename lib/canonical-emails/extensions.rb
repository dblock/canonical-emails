module CanonicalEmails
  module Extensions
    extend ActiveSupport::Concern

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
