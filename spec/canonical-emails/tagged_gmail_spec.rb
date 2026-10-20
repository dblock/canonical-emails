# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::TaggedGMail do
  it 'normalizes Gmail periods and case without removing plus-tags' do
    address = described_class.parse('Alex Smith <Alex.Smith+Newsletter+Offers@GMAIL.COM>')

    expect(address).to be_instance_of(described_class)
    expect(address.to_s).to eq('Alex Smith <alexsmith+newsletter+offers@gmail.com>')
    expect(address.username).to eq('Alex.Smith+Newsletter+Offers')
    expect(address.tag).to be_nil
  end

  it 'is available explicitly without changing default Gmail dispatch' do
    value = 'Alex.Smith+Newsletter@gmail.com'

    expect(CanonicalEmails.parse(value)).to be_instance_of(CanonicalEmails::GMail)
    expect(CanonicalEmails.parse(value, type: described_class)).to be_instance_of(described_class)
    expect(described_class.parse(nil)).to be_nil
  end

  it 'preserves an empty plus suffix' do
    address = described_class.parse('Alex.Smith+@gmail.com')
    expect(address.address).to eq('alexsmith+@gmail.com')

    expect(address.username).to eq('Alex.Smith+')
    expect(address.tag).to be_nil
  end

  it 'enforces the Gmail domain for parsing' do
    expect { described_class.parse('Alex@outlook.com') }.to raise_error(ArgumentError, /does not support domain/)
  end

  it 'can be selected by a model accessor' do
    model = Class.new do
      include CanonicalEmails::Extensions

      attr_accessor :email

      canonical_email :email, type: CanonicalEmails::TaggedGMail
    end.new
    model.email = 'Alex.Smith+Newsletter@GMAIL.COM'

    expect(model.canonical_email).to be_instance_of(described_class)
    expect(model.canonical_email.address).to eq('alexsmith+newsletter@gmail.com')
  end
end
