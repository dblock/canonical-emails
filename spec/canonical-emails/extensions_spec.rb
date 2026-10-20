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

  it 'names accessors independently while preserving source fields and types' do
    user = Class.new do
      include CanonicalEmails::Extensions

      attr_accessor :email, :backup_email

      canonical_email :email, as: :normalized_email
      canonical_email :backup_email, as: 'normalized_backup', type: CanonicalEmails::TaggedGMail
    end.new
    user.email = 'Alex.Smith+Newsletter@gmail.com'
    user.backup_email = 'Alex.Smith+Backup@gmail.com'

    expect(user.normalized_email.address).to eq('alexsmith@gmail.com')
    expect(user.normalized_backup).to be_instance_of(CanonicalEmails::TaggedGMail)
    expect(user.normalized_backup.address).to eq('alexsmith+backup@gmail.com')
    expect(user).not_to respond_to(:canonical_email, :canonical_backup_email)
    expect(user.email).to eq('Alex.Smith+Newsletter@gmail.com')
    expect(user.backup_email).to eq('Alex.Smith+Backup@gmail.com')

    user.email = nil
    expect(user.normalized_email).to be_nil
    expect(user.normalized_backup.address).to eq('alexsmith+backup@gmail.com')
  end

  it 'wraps source readers for String and Symbol names without changing the writer' do
    [:email, 'email'].each do |field|
      [:email, 'email'].each do |name|
        klass = model_class

        klass.canonical_email(field, as: name)
        user = klass.new
        expect(user.email).to be_nil
        user.email = 'Alex.Smith+Newsletter@gmail.com'
        expect(user.email).to be_instance_of(CanonicalEmails::GMail)
        expect(user.email.address).to eq('alexsmith@gmail.com')
        expect(user.email.username).to eq('Alex.Smith+Newsletter')
        expect(user.instance_variable_get(:@email)).to eq('Alex.Smith+Newsletter@gmail.com')
      end
    end
  end

  it 'rejects invalid accessor names' do
    [nil, '', 123].each do |name|
      expect { model_class(as: name) }.to raise_error(ArgumentError, /nonempty String or Symbol/)
    end
  end

  it 'wraps readers defined after the declaration and supports repeated configuration' do
    klass = Class.new do
      include CanonicalEmails::Extensions

      canonical_email :email, as: :email
      canonical_email :email, as: :email, type: CanonicalEmails::TaggedGMail

      attr_accessor :email
    end
    user = Class.new(klass).new
    user.email = 'Alex.Smith+Newsletter@gmail.com'

    expect(user.email).to be_instance_of(CanonicalEmails::TaggedGMail)
    expect(user.email.address).to eq('alexsmith+newsletter@gmail.com')
  end

  it 'wraps inherited readers and propagates provider errors without changing stored input' do
    parent = Class.new { attr_accessor :email }
    klass = Class.new(parent) do
      include CanonicalEmails::Extensions

      canonical_email :email, as: :email, type: CanonicalEmails::GMail
    end
    user = klass.new
    user.email = 'Alex@outlook.com'

    expect { user.email }.to raise_error(ArgumentError, /does not support domain/)
    expect(user.instance_variable_get(:@email)).to eq('Alex@outlook.com')
  end

  it 'rejects provider mismatches and old positional transformer arguments' do
    user = model_class(type: CanonicalEmails::GMail).new
    user.email = 'Alex@outlook.com'

    expect { user.canonical_email }.to raise_error(ArgumentError, /does not support domain/)
    expect { model_class.canonical_email(:email, CanonicalEmails::GMail) }.to raise_error(ArgumentError)
  end

  [false, true].each do |override|
    it "caches unchanged input and refreshes changed input with override=#{override}" do
      user = model_class(**(override ? { as: :email } : {})).new
      reader = override ? :email : :canonical_email
      raw = +'Alex.Smith+Newsletter@gmail.com'
      user.email = raw
      expect(CanonicalEmails).to receive(:parse).with(raw, type: nil).once.and_call_original
      address = user.public_send(reader)
      expect(user.public_send(reader)).to equal(address)
      expect(address.to_s).to eq('alexsmith@gmail.com')

      expect { address.address = 'Alex@gmail.com' }.to raise_error(NoMethodError)
      expect(user.instance_variable_get(:@email)).to eq(raw)

      raw.replace('Alex.Smith+Work@gmail.com')
      expect(CanonicalEmails).to receive(:parse).with(raw, type: nil).once.and_call_original
      refreshed = user.public_send(reader)
      expect(refreshed).not_to equal(address)
      expect(refreshed.tag).to eq('Work')
      expect(user.public_send(reader)).to equal(refreshed)

      user.instance_variable_set(:@email, 'Alex@EXAMPLE.COM')
      expect(CanonicalEmails).to receive(:parse).with('Alex@EXAMPLE.COM', type: nil).once.and_call_original
      expect(user.public_send(reader)).to be_instance_of(CanonicalEmails::Address)

      user.email = nil
      expect(CanonicalEmails).to receive(:parse).with(nil, type: nil).once.and_call_original
      2.times { expect(user.public_send(reader)).to be_nil }
    end
  end

  it 'keeps cached results separate between instances and accessor configurations' do
    klass = model_class
    klass.canonical_email :email, as: :tagged_email, type: CanonicalEmails::TaggedGMail
    first = klass.new
    second = klass.new
    first.email = second.email = 'Alex.Smith+Newsletter@gmail.com'

    expect(first.canonical_email).not_to equal(second.canonical_email)
    expect(first.tagged_email.address).to eq('alexsmith+newsletter@gmail.com')
    expect(first.canonical_email.address).to eq('alexsmith@gmail.com')

    klass.canonical_email :email, type: CanonicalEmails::TaggedGMail
    expect(first.canonical_email).to be_instance_of(CanonicalEmails::TaggedGMail)
  end

  it 'does not cache failures or return stale results for invalid input' do
    user = model_class(type: CanonicalEmails::GMail).new
    user.email = 'Alex@gmail.com'
    previous = user.canonical_email
    user.email = 'Alex@outlook.com'

    2.times { expect { user.canonical_email }.to raise_error(ArgumentError, /does not support domain/) }
    user.email = 'Alex@gmail.com'
    expect(user.canonical_email).to equal(previous)
  end
end
