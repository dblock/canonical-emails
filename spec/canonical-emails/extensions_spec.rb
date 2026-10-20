# frozen_string_literal: true

require 'spec_helper'

describe CanonicalEmails::Extensions do
  def model_class(**options)
    Class.new do
      include CanonicalEmails::Extensions

      attr_accessor :email

      canonical_email :email, **options
    end
  end

  it 'dispatches based on the current value by default' do
    user = model_class.new
    expect(user.canonical_email).to be_nil

    user.email = 'Alex Smith <Alex.Smith+Newsletter@GMAIL.COM>'
    expect(user.canonical_email).to be_instance_of(CanonicalEmails::GMail)
    expect(user.canonical_email.to_s).to eq('Alex Smith <alexsmith@gmail.com>')
    expect(user.canonical_email.username).to eq('Alex.Smith+Newsletter')
    expect(user.canonical_email.tag).to eq('Newsletter')

    user.email = 'Alex.Smith+Newsletter@EXAMPLE.COM'
    expect(user.canonical_email).to be_instance_of(CanonicalEmails::Address)
    expect(user.canonical_email.address).to eq(user.email)
  end

  it 'uses an explicit type instead of provider dispatch' do
    user = model_class(type: CanonicalEmails::Downcase).new
    user.email = 'Alex.Smith+Newsletter@GMAIL.COM'

    expect(user.canonical_email).to be_instance_of(CanonicalEmails::Downcase)
    expect(user.canonical_email.address).to eq('alex.smith+newsletter@gmail.com')
  end

  it 'keeps multiple fields and their type selections independent' do
    user = Class.new do
      include CanonicalEmails::Extensions

      attr_accessor :email, :backup_email

      canonical_email :email
      canonical_email :backup_email, type: CanonicalEmails::TaggedGMail
    end.new
    user.email = 'Alex.Smith+Newsletter@gmail.com'
    user.backup_email = 'Alex.Smith+Backup@gmail.com'

    expect(user.canonical_email).to be_instance_of(CanonicalEmails::GMail)
    expect(user.canonical_email.address).to eq('alexsmith@gmail.com')
    expect(user.canonical_email.tag).to eq('Newsletter')
    expect(user.canonical_backup_email).to be_instance_of(CanonicalEmails::TaggedGMail)
    expect(user.canonical_backup_email.address).to eq('alexsmith+backup@gmail.com')
    expect(user.email).to eq('Alex.Smith+Newsletter@gmail.com')
    expect(user.backup_email).to eq('Alex.Smith+Backup@gmail.com')

    user.email = 'Alex@EXAMPLE.COM'
    expect(user.canonical_email).to be_instance_of(CanonicalEmails::Address)
    expect(user.canonical_email.address).to eq('Alex@EXAMPLE.COM')
    expect(user.canonical_backup_email.address).to eq('alexsmith+backup@gmail.com')

    user.backup_email = nil
    expect(user.canonical_backup_email).to be_nil
    expect(user.canonical_email.address).to eq('Alex@EXAMPLE.COM')
  end

  it 'rejects provider mismatches and old positional transformer arguments' do
    user = model_class(type: CanonicalEmails::GMail).new
    user.email = 'Alex@outlook.com'

    expect { user.canonical_email }.to raise_error(ArgumentError, /does not support domain/)
    expect { model_class.canonical_email(:email, CanonicalEmails::GMail) }.to raise_error(ArgumentError)
  end
end
