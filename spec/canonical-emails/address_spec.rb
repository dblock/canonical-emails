# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::Address do
  it 'preserves the address without opting into transformations' do
    address = described_class.parse('Alex Smith <Alex.Smith+Newsletter@EXAMPLE.COM>')

    expect(address.to_s).to eq('Alex Smith <Alex.Smith+Newsletter@EXAMPLE.COM>')
    expect(address.username).to eq('Alex.Smith+Newsletter')
    expect(address.tag).to be_nil
  end

  {
    DowncaseLocal: ['alex.smith+newsletter@EXAMPLE.COM', nil],
    DowncaseDomain: ['Alex.Smith+Newsletter@example.com', nil],
    RemovePeriods: ['AlexSmith+Newsletter@EXAMPLE.COM', nil],
    StripTags: ['Alex.Smith@EXAMPLE.COM', 'Newsletter']
  }.each do |behavior, (expected, tag)|
    it "opts into #{behavior} independently" do
      parser = Class.new(described_class) do
        include CanonicalEmails::Behaviors.const_get(behavior)
      end
      address = parser.parse('Alex.Smith+Newsletter@EXAMPLE.COM')

      expect(address.address).to eq(expected)
      expect(address.username).to eq('Alex.Smith+Newsletter')
      expect(address.tag).to eq(tag)
      expect(parser.parse(nil)).to be_nil
      empty = parser.parse('')
      expect(empty.to_s).to eq('')
      expect(empty.local).to be_nil
      expect(empty.domain).to be_nil
    end
  end

  it 'can normalize periods and case without removing plus-tags' do
    parser = Class.new(described_class) do
      include CanonicalEmails::Behaviors::DowncaseLocal
      include CanonicalEmails::Behaviors::DowncaseDomain
      include CanonicalEmails::Behaviors::RemovePeriods
    end
    address = parser.parse('Alex.Smith+Newsletter@GMAIL.COM')

    expect(address.address).to eq('alexsmith+newsletter@gmail.com')
    expect(address.username).to eq('Alex.Smith+Newsletter')
    expect(address.tag).to be_nil
  end

  it 'refreshes the username and cached display name when reassigned' do
    address = described_class.parse('Alex Smith <Alex@EXAMPLE.COM>')
    expect(address.to_s).to eq('Alex Smith <Alex@EXAMPLE.COM>')

    address.address = 'Taylor Jones <Taylor+Work@gmail.com>'
    expect(address.to_s).to eq('Taylor Jones <Taylor+Work@gmail.com>')
    expect(address.username).to eq('Taylor+Work')
    expect(address.tag).to be_nil
    expect(address).to be_instance_of(described_class)

    address.address = nil
    expect(address.to_s).to eq('')
    expect(address.username).to be_nil
  end

  it 'leaves the address unchanged when reassignment cannot be parsed' do
    address = described_class.parse('Alex@EXAMPLE.COM')

    expect { address.address = 123 }.to raise_error(TypeError)
    expect { address.address = 'Alex <' }.to raise_error(Mail::Field::ParseError)
    expect(address.address).to eq('Alex@EXAMPLE.COM')
  end
end
