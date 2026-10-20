# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::Downcase do
  it 'preserves nil and supports empty and domainless addresses' do
    expect(described_class.parse(nil)).to be_nil
    expect(described_class.parse('').local).to be_nil
    expect(described_class.parse('').domain).to be_nil
    expect(described_class.parse('Alex').to_s).to eq('alex')
  end

  it_behaves_like 'parse fixture_examples'
end
