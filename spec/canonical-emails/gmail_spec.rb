# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::GMail do
  it 'normalizes Gmail input and preserves original metadata' do
    address = described_class.parse('Alex Smith <Alex.Smith+Newsletter+Offers@GMAIL.COM>')

    expect(address).to be_instance_of(described_class)
    expect(address.to_s).to eq('Alex Smith <alexsmith@gmail.com>')
    expect(address.username).to eq('Alex.Smith+Newsletter+Offers')
    expect(address.tag).to eq('Newsletter+Offers')
  end

  it 'returns nil for nil input' do
    expect(described_class.parse(nil)).to be_nil
  end

  ['Alex@EXAMPLE.COM', 'Alex@gmail.com.example.org', 'Alex@googlemail.com', 'Alex', ''].each do |value|
    it "rejects non-Gmail input #{value.inspect}" do
      expect { described_class.parse(value) }.to raise_error(ArgumentError, /does not support domain/)
    end
  end

  it 'rejects mismatched input through its constructor as well' do
    expect { described_class.new('Alex@EXAMPLE.COM') }.to raise_error(ArgumentError, /does not support domain/)
  end

  it_behaves_like 'parse fixture_examples', CanonicalEmails
end
