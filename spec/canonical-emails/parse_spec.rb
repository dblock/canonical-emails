# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails do
  it 'selects Gmail only for the exact provider domain, ignoring case' do
    expect(described_class.parse('Alex.Smith+Newsletter@GMAIL.COM')).to be_instance_of(CanonicalEmails::GMail)

    %w[EXAMPLE.COM outlook.com gmail.com.example.org googlemail.com].each do |domain|
      address = described_class.parse("Alex.Smith+Newsletter@#{domain}")

      expect(address).to be_instance_of(CanonicalEmails::Address)
      expect(address.address).to eq("Alex.Smith+Newsletter@#{domain}")
      expect(address.username).to eq('Alex.Smith+Newsletter')
      expect(address.tag).to be_nil
    end
  end

  it 'returns nil for nil and generic addresses for empty or domainless input' do
    expect(described_class.parse(nil)).to be_nil
    expect(described_class.parse('')).to be_instance_of(CanonicalEmails::Address)
    expect(described_class.parse(" \t").to_s).to eq('')
    expect(described_class.parse('Alex').address).to eq('Alex')
  end

  it 'returns the explicitly requested class without auto-detection' do
    generic = described_class.parse('Alex.Smith+Newsletter@GMAIL.COM', type: CanonicalEmails::Address)
    downcase = described_class.parse('Alex.Smith+Newsletter@GMAIL.COM', type: CanonicalEmails::Downcase)

    expect(generic).to be_instance_of(CanonicalEmails::Address)
    expect(generic.address).to eq('Alex.Smith+Newsletter@GMAIL.COM')
    expect(downcase).to be_instance_of(CanonicalEmails::Downcase)
    expect(downcase.address).to eq('alex.smith+newsletter@gmail.com')
  end

  it 'supports custom types and preserves original metadata' do
    type = Class.new(CanonicalEmails::Address) do
      include CanonicalEmails::Behaviors::DowncaseDomain
    end

    address = described_class.parse('Alex.Smith+Newsletter@EXAMPLE.COM', type: type)

    expect(address).to be_instance_of(type)
    expect(address.address).to eq('Alex.Smith+Newsletter@example.com')
    expect(address.username).to eq('Alex.Smith+Newsletter')
  end

  it 'enforces custom provider restrictions while retaining plus-tags' do
    type = Class.new(CanonicalEmails::Address) do
      include CanonicalEmails::Behaviors::DowncaseLocal
      include CanonicalEmails::Behaviors::DowncaseDomain
      include CanonicalEmails::Behaviors::RemovePeriods

      def self.accepts?(domain)
        domain&.casecmp?('gmail.com')
      end
    end
    address = described_class.parse('Alex.Smith+Newsletter@GMAIL.COM', type: type)

    expect(address.address).to eq('alexsmith+newsletter@gmail.com')
    expect(address.username).to eq('Alex.Smith+Newsletter')
    expect { described_class.parse('Alex@outlook.com', type: type) }.to raise_error(ArgumentError)
  end

  it 'rejects invalid types, input types, and mismatched providers explicitly' do
    [String, Object.new].each do |type|
      expect { described_class.parse('Alex@gmail.com', type: type) }.to raise_error(ArgumentError, /type must be/)
    end
    expect { described_class.parse(123) }.to raise_error(TypeError, /String or nil/)
    expect { described_class.parse('Alex@outlook.com', type: CanonicalEmails::GMail) }.to raise_error(ArgumentError, /does not support domain/)
  end

  it 'parses the input once without serializing away the original metadata' do
    expect(Mail::Parsers::AddressListsParser).to receive(:parse).with('Alex.Smith+Newsletter@GMAIL.COM').once.and_call_original

    address = described_class.parse('Alex.Smith+Newsletter@GMAIL.COM')
    expect(address.username).to eq('Alex.Smith+Newsletter')
    expect(address.tag).to eq('Newsletter')
  end

  it 'propagates malformed address errors' do
    expect { described_class.parse('Alex <') }.to raise_error(Mail::Field::ParseError)
  end
end
