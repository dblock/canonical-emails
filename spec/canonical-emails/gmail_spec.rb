# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::GMail do
  it 'returns an empty Mail address for nil input' do
    address = subject.transform(nil)

    expect(address).to be_a(Mail::Address)
    expect(address.to_s).to eq('')
  end

  it 'supports clearing an address after transformation' do
    address = subject.transform('Donald.Duck@gmail.com')
    address.address = ''

    expect(address.local).to be_nil
    expect(address.domain).to be_nil
    expect(address.to_s).to eq('')
  end

  it_behaves_like 'transform fixture_examples'
end
