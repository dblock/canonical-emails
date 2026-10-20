CanonicalEmails
==============

[![Gem Version](http://img.shields.io/gem/v/canonical-emails.svg)](http://badge.fury.io/rb/canonical-emails)
[![CI](https://github.com/dblock/canonical-emails/actions/workflows/ci.yml/badge.svg)](https://github.com/dblock/canonical-emails/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/dblock/canonical-emails/badge.svg?branch=master)](https://coveralls.io/github/dblock/canonical-emails?branch=master)

Combine email validation and transformations to produce canonical email addresses. For example, parse and transform `Donald Duck <donald.duck@gmail.com>` into `donaldduck@gmail.com`, for `@gmail.com` addresses only. Patches instances of `Mail::Address`.

### Install

Add `canonical-emails` to your Gemfile.

Requires Ruby 3.1 or newer. Use a Ruby version compatible with your selected ActiveSupport release.

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

Gmail.com e-mail addresses ignore periods, aren't case-sensitive, and support plus-address tags. The canonical version removes periods and the first `+` and everything after it from the local part, and normalizes case. Addresses on other domains are left unchanged, including Outlook.com and custom domains hosted by Google Workspace; Gmail's period-removal rules must not be applied to them.

`GMail` lowercases the domain only when it is `gmail.com` (matched case-insensitively). For compatibility, it preserves both local-part and domain casing for all other domains: `Donald.Duck@EXAMPLE.COM` remains `Donald.Duck@EXAMPLE.COM`. Email domains are case-insensitive; preserving their case is not a requirement of email addressing. Use `CanonicalEmails::Downcase` when you want to lowercase both the local part and domain regardless of provider.

``` ruby
email = CanonicalEmails::GMail.transform("Donald Duck <donald.duck@gmail.com>")
email.to_s # "Donald Duck <donaldduck@gmail.com>"
email.local # "donaldduck"
email.address # "donaldduck@gmail.com"
```

The returned `CanonicalEmails::GMail::Address` inherits from `Mail::Address` and stores the removed suffix in its read-only `tag` property, preserving its case and any additional `+` characters. It returns `nil` when no tag is present or the address is not on Gmail, and `""` for an explicitly empty tag (`donald.duck+@gmail.com`). Like the address, the tag reflects subsequent assignments to `email.address`.

The read-only `username` property preserves the original local part before normalization, including case, periods, and the full plus-tag, for any domain. It returns `nil` for empty addresses. Both properties refresh when `email.address` is reassigned.

``` ruby
email = CanonicalEmails::GMail.transform("Donald Duck <Donald.Duck+News+Offers@GMAIL.COM>")
email.address # "donaldduck@gmail.com"
email.username # "Donald.Duck+News+Offers"
email.tag # "News+Offers"
```

### Validation

Canonicalization is not validation. Transformations use `Mail::Address` parsing, which may reject malformed input but also accepts forms without a domain. They do not establish RFC compliance, DNS existence, mailbox ownership, or deliverability. Apply your application's validation policy separately and verify ownership with a confirmation email when needed.

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
