CanonicalEmails
==============

[![Gem Version](http://img.shields.io/gem/v/canonical-emails.svg)](http://badge.fury.io/rb/canonical-emails)
[![Build Status](http://img.shields.io/travis/dblock/canonical-emails.svg)](https://travis-ci.org/dblock/canonical-emails)
[![Dependency Status](https://gemnasium.com/dblock/canonical-emails.svg)](https://gemnasium.com/dblock/canonical-emails)
[![Code Climate](https://codeclimate.com/github/dblock/canonical-emails.svg)](https://codeclimate.com/github/dblock/canonical-emails)

Combine email validation and transformations to produce canonical email addresses. For example, parse and transform `Donald Duck <donald.duck@gmail.com>` into `donaldduck@gmail.com`, for `@gmail.com` addresses only. Patches instances of `Mail::Address`.

### Install

Add `canonical-emails` to your Gemfile.

```
gem 'canonical-emails'
```

### Use

``` ruby
class User
  include CanonicalEmails::Extensions

  attr_accessor :email
  canonical_email :email, CanonicalEmails::GMail
end

user = User.new
user.email = "Donald Duck <Donald.Duck@gmail.com>"
user.canonical_email.class # Mail::Address
user.canonical_email.to_s # "Donald Duck <donaldduck@gmail.com>"
user.canonical_email.address # "donaldduck@gmail.com"
```

### Transform

#### CanonicalEmails::Downcase

Replaces the address and domain portion of the email by its lowercase equivalent.

``` ruby
email = CanonicalEmails::Downcase.transform("Donald Duck <DoNaLD.DuCK@eXaMPLe.CoM>")
email.to_s # "Donald Duck <donald.duck@example.com>"
email.address # "donald.duck@example.com"
```

#### CanonicalEmails::GMail

Gmail.com e-mail addresses ignore periods and aren't case-sensitive. The canonical version removes them and changes the address portion to lowercase.

``` ruby
email = CanonicalEmails::GMail.transform("Donald Duck <donald.duck@gmail.com>")
email.to_s # "Donald Duck <donaldduck@gmail.com>"
email.local # "donaldduck"
email.address # "donaldduck@gmail.com"
```

### Multiple Transformations

Combine multiple transformations, executed from left to right.

```
canonical_email :email, CanonicalEmails::GMail, CanonicalEmails::...
```

### Custom Transformations

A transformation is a module that has a single `transform` method that returns a `Mail::Address` instance. This library patches internal methods of the `Mail::Address` class.

``` ruby
module CanonicalEmails
  module ReverseName
    def self.transform(value)
      Mail::Address.new(value).tap do |email|
        email.instance_eval do
          def name
            super.reverse
          end
        end
      end
    end
  end
end

email = CanonicalEmails::ReverseName.transform("Donald Duck <donald@example.org>")
email.name # "kcuD dlanoD"
```

### Contribute

See [CONTRIBUTING](CONTRIBUTING.md).

### Copyright and License

Copyright Daniel Doubrovkine and Contributors, [Artsy](https://artsy.net), 2013-2014

[MIT License](LICENSE.md)
