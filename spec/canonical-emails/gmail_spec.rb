# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::GMail do
  it 'returns an empty Mail address for nil input' do
    address = subject.transform(nil)

    expect(address).to be_a(Mail::Address)
    expect(address.to_s).to eq('')
    expect(address.tag).to be_nil
    expect(address.username).to be_nil
  end

  it 'supports clearing an address after transformation' do
    address = subject.transform('Donald.Duck@gmail.com')
    address.address = ''

    expect(address.local).to be_nil
    expect(address.domain).to be_nil
    expect(address.to_s).to eq('')
    expect(address.tag).to be_nil
    expect(address.username).to be_nil
  end

  it 'does not expose tags for domainless addresses' do
    address = subject.transform('donald+News')

    expect(address.tag).to be_nil
    expect(address.username).to eq('donald+News')
  end

  it 'updates the username and tag when the address changes' do
    address = subject.transform('donald.duck+Old@gmail.com')
    address.address = 'donald.duck+New+Tag@gmail.com'

    expect(address.tag).to eq('New+Tag')
    expect(address.username).to eq('donald.duck+New+Tag')
    expect(address.address).to eq('donaldduck@gmail.com')

    address.address = 'Donald.Duck+Other@EXAMPLE.COM'

    expect(address.tag).to be_nil
    expect(address.username).to eq('Donald.Duck+Other')
    expect(address.address).to eq('Donald.Duck+Other@EXAMPLE.COM')

    address.address = 'Donald.Duck+Back@GMAIL.COM'

    expect(address.tag).to eq('Back')
    expect(address.username).to eq('Donald.Duck+Back')
    expect(address.address).to eq('donaldduck@gmail.com')
  end

  it_behaves_like 'transform fixture_examples'
end
