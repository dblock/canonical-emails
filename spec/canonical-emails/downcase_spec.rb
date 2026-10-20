# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::Downcase do
  it 'preserves nil and supports empty and domainless addresses' do
    expect(subject.transform(nil)).to be_nil
    expect(subject.transform('').local).to be_nil
    expect(subject.transform('').domain).to be_nil
    expect(subject.transform('Donald').to_s).to eq('donald')
  end

  it_behaves_like 'transform fixture_examples'
end
