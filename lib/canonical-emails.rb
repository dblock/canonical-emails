# frozen_string_literal: true

require 'mail'
require 'active_support/concern'

require 'canonical-emails/version'
require 'canonical-emails/address'
require 'canonical-emails/behaviors'
require 'canonical-emails/downcase'
require 'canonical-emails/tagged_gmail'
require 'canonical-emails/gmail'
require 'canonical-emails/extensions'

# Parses addresses into provider-aware canonical forms.
module CanonicalEmails
  @types = {}
  @types_mutex = Mutex.new

  def self.clear
    @types_mutex.synchronize { @types.clear }
  end

  def self.register(domain, type:)
    raise ArgumentError, 'domain must be a nonempty domain String without whitespace or @' unless domain.is_a?(String) && !domain.empty? && !domain.match?(/[\s@]/)
    raise ArgumentError, 'type must be a CanonicalEmails::Address subclass' unless type.is_a?(Class) && type <= Address

    domain = domain.downcase
    raise ArgumentError, "#{type} does not accept #{domain}" unless type.accepts?(domain)

    @types_mutex.synchronize do
      existing = @types[domain]
      raise ArgumentError, "#{domain} is already registered to #{existing}" if existing && existing != type

      @types[domain] = type
    end
  end

  def self.parse(value, type: nil)
    raise ArgumentError, 'type must be a CanonicalEmails::Address subclass' unless type.nil? || (type.is_a?(Class) && type <= Address)
    return if value.nil?

    raise TypeError, 'address must be a String or nil' unless value.is_a?(String)

    data = Mail::Parsers::AddressListsParser.parse(value).addresses.first unless value.strip.empty?
    type ||= @types_mutex.synchronize { @types.fetch(data&.domain&.downcase, Address) }
    type.new(data)
  end

  register('gmail.com', type: GMail)
end
