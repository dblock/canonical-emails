# frozen_string_literal: true

require 'mail'
require 'active_support/concern'

require 'canonical-emails/version'
require 'canonical-emails/address'
require 'canonical-emails/behaviors'
require 'canonical-emails/downcase'
require 'canonical-emails/gmail'
require 'canonical-emails/extensions'

# Parses addresses into provider-aware canonical forms.
module CanonicalEmails
  def self.parse(value, type: nil)
    raise ArgumentError, 'type must be a CanonicalEmails::Address subclass' unless type.nil? || (type.is_a?(Class) && type <= Address)
    return if value.nil?

    raise TypeError, 'address must be a String or nil' unless value.is_a?(String)

    data = Mail::Parsers::AddressListsParser.parse(value).addresses.first unless value.strip.empty?
    type ||= GMail.accepts?(data&.domain) ? GMail : Address
    type.new(data)
  end
end
