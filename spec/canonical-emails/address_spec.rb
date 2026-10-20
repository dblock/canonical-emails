# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::Address do
  it 'preserves the address without opting into transformations' do
    address = described_class.transform('Donald Duck <Donald.Duck+News@EXAMPLE.COM>')

    expect(address.to_s).to eq('Donald Duck <Donald.Duck+News@EXAMPLE.COM>')
    expect(address.username).to eq('Donald.Duck+News')
    expect(address.tag).to be_nil
  end

  {
    DowncaseLocal: ['donald.duck+news@EXAMPLE.COM', nil],
    DowncaseDomain: ['Donald.Duck+News@example.com', nil],
    RemovePeriods: ['DonaldDuck+News@EXAMPLE.COM', nil],
    StripTags: ['Donald.Duck@EXAMPLE.COM', 'News']
  }.each do |behavior, (expected, tag)|
    it "opts into #{behavior} independently" do
      parser = Class.new(described_class) do
        include CanonicalEmails::Behaviors.const_get(behavior)
      end
      address = parser.transform('Donald.Duck+News@EXAMPLE.COM')

      expect(address.address).to eq(expected)
      expect(address.username).to eq('Donald.Duck+News')
      expect(address.tag).to eq(tag)
      empty = parser.transform(nil)
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
    address = parser.transform('Donald.Duck+News@GMAIL.COM')

    expect(address.address).to eq('donaldduck+news@gmail.com')
    expect(address.username).to eq('Donald.Duck+News')
    expect(address.tag).to be_nil
  end
end
