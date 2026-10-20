# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails do
  around do |example|
    original = described_class.instance_variable_get(:@types)
    described_class.instance_variable_set(:@types, original.dup)
    example.run
  ensure
    described_class.instance_variable_set(:@types, original)
  end

  let(:provider) do
    Class.new(CanonicalEmails::Address) do
      include CanonicalEmails::Behaviors::DowncaseDomain

      def self.accepts?(domain)
        domain&.casecmp?('provider.example')
      end
    end
  end

  it 'opts custom types into exact case-insensitive dispatch without losing metadata' do
    expect(described_class.parse('Alex.Smith+Newsletter@provider.example')).to be_instance_of(CanonicalEmails::Address)

    described_class.register('PROVIDER.EXAMPLE', type: provider)
    address = described_class.parse('Alex.Smith+Newsletter@PrOvIdEr.ExAmPlE')

    expect(address).to be_instance_of(provider)
    expect(address.address).to eq('Alex.Smith+Newsletter@provider.example')
    expect(address.username).to eq('Alex.Smith+Newsletter')
    expect(address.tag).to be_nil
    expect(described_class.parse('Alex@sub.provider.example')).to be_instance_of(CanonicalEmails::Address)
    expect(described_class.parse('Alex@provider.example.other')).to be_instance_of(CanonicalEmails::Address)
  end

  it 'allows repeated identical registration but rejects conflicting types without replacement' do
    2.times { described_class.register('provider.example', type: provider) }

    expect { described_class.register('PROVIDER.EXAMPLE', type: CanonicalEmails::Address) }.to raise_error(ArgumentError, /already registered/)
    expect(described_class.parse('Alex@provider.example')).to be_instance_of(provider)
    expect { described_class.register('gmail.com', type: CanonicalEmails::Address) }.to raise_error(ArgumentError, /already registered/)
  end

  it 'validates domains and types before changing the registry' do
    [nil, 123, '', ' provider.example', 'Alex@provider.example'].each do |domain|
      expect { described_class.register(domain, type: provider) }.to raise_error(ArgumentError, /domain must be/)
    end

    [nil, String, Object.new].each do |type|
      expect { described_class.register('provider.example', type: type) }.to raise_error(ArgumentError, /type must be/)
    end
    expect { described_class.register('other.example', type: provider) }.to raise_error(ArgumentError, /does not accept/)
    expect(described_class.parse('Alex@other.example')).to be_instance_of(CanonicalEmails::Address)
  end

  it 'clears all providers without restoring defaults or affecting explicit types' do
    described_class.register('provider.example', type: provider)
    2.times { described_class.clear }

    value = 'Alex.Smith+Newsletter@gmail.com'
    address = described_class.parse(value)
    expect(address).to be_instance_of(CanonicalEmails::Address)
    expect(address.address).to eq(value)
    expect(described_class.parse('Alex@provider.example')).to be_instance_of(CanonicalEmails::Address)
    expect(described_class.parse(value, type: CanonicalEmails::GMail)).to be_instance_of(CanonicalEmails::GMail)
    expect(CanonicalEmails::TaggedGMail.parse(value)).to be_instance_of(CanonicalEmails::TaggedGMail)

    described_class.register('gmail.com', type: CanonicalEmails::TaggedGMail)
    tagged = described_class.parse(value)
    expect(tagged).to be_instance_of(CanonicalEmails::TaggedGMail)
    expect(tagged.address).to eq('alexsmith+newsletter@gmail.com')
  end

  it 'bypasses registration for explicit types and class-level parsing' do
    described_class.register('provider.example', type: provider)

    expect(described_class.parse('Alex@provider.example', type: CanonicalEmails::Address)).to be_instance_of(CanonicalEmails::Address)
    expect(CanonicalEmails::Address.parse('Alex@provider.example')).to be_instance_of(CanonicalEmails::Address)
    expect(described_class.parse('Alex@gmail.com')).to be_instance_of(CanonicalEmails::GMail)
  end

  it 'uses registrations through model accessors' do
    described_class.register('provider.example', type: provider)
    model = Class.new do
      include CanonicalEmails::Extensions

      attr_accessor :email

      canonical_email :email
    end.new
    model.email = 'Alex@PROVIDER.EXAMPLE'

    expect(model.canonical_email).to be_instance_of(provider)
    expect(model.canonical_email.domain).to eq('provider.example')
  end
end
