CanonicalEmails
==============

[![Gem Version](http://img.shields.io/gem/v/canonical-emails.svg)](http://badge.fury.io/rb/canonical-emails)
[![CI](https://github.com/dblock/canonical-emails/actions/workflows/ci.yml/badge.svg)](https://github.com/dblock/canonical-emails/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/dblock/canonical-emails/badge.svg?branch=master)](https://coveralls.io/github/dblock/canonical-emails?branch=master)

Parse email addresses into provider-aware canonical forms. Gmail addresses become `CanonicalEmails::GMail` instances; unsupported domains become unchanged `CanonicalEmails::Address` instances. Both inherit from `Mail::Address`.

### Install

Add `canonical-emails` to your Gemfile. Requires Ruby 3.1 or newer and compatible Mail and ActiveSupport versions.

```ruby
gem 'canonical-emails'
```

See [UPGRADING.md](UPGRADING.md) for breaking API changes, Gmail plus-tag behavior, and migration considerations for stored canonical addresses.

### Parse

```ruby
email = CanonicalEmails.parse("Alex Smith <Alex.Smith+Newsletter+Offers@GMAIL.COM>")
email.class # CanonicalEmails::GMail
email.to_s # "Alex Smith <alexsmith@gmail.com>"
email.address # "alexsmith@gmail.com"
email.local # "alexsmith"
email.domain # "gmail.com"
email.username # "Alex.Smith+Newsletter+Offers"
email.tag # "Newsletter+Offers"

email = CanonicalEmails.parse("Alex.Smith+Newsletter@EXAMPLE.COM")
email.class # CanonicalEmails::Address
email.address # "Alex.Smith+Newsletter@EXAMPLE.COM"
```

Provider detection matches the complete domain case-insensitively. Only `gmail.com` is currently recognized; Outlook, `googlemail.com`, and Google Workspace custom domains remain generic. No Outlook period or plus-tag equivalence is assumed.

`parse(nil)` returns `nil`. Empty or whitespace-only strings return empty generic addresses. Domainless input remains a generic address. Non-string input raises `TypeError`; malformed input may raise Mail parsing errors.

The read-only `username` property preserves the original local part, including case, periods, and plus-tags. `tag` preserves the removed suffix, including case and additional `+` characters, when tag stripping is enabled. A missing tag returns `nil`; an explicitly empty Gmail tag (`alex.smith+@gmail.com`) returns `""`. Unsupported providers have `tag == nil`.

Assign a new string with `email.address = value` to refresh normalization, `username`, `tag`, and cached display-name/comment formatting. The object's class stays the same: Gmail objects reject non-Gmail, empty, and nil assignments with `ArgumentError`. Rejected assignments leave the existing address unchanged. Generic addresses accept any domain and can be cleared with nil or an empty string. To auto-detect a different provider, call `CanonicalEmails.parse` again instead.

### Explicit Types

Specify `type:` to request an exact address class instead of provider detection:

```ruby
email = CanonicalEmails.parse("Alex.Smith+Newsletter@GMAIL.COM", type: CanonicalEmails::Address)
email.address # "Alex.Smith+Newsletter@GMAIL.COM" (no normalization)

email = CanonicalEmails.parse("Alex.Smith+Newsletter@GMAIL.COM", type: CanonicalEmails::Downcase)
email.address # "alex.smith+newsletter@gmail.com" (lowercase both parts only)
```

`type:` must be `CanonicalEmails::Address` or one of its subclasses. Classes also expose `.parse`, equivalent to specifying `type:`:

```ruby
CanonicalEmails::GMail.parse("Alex.Smith+Newsletter@GMAIL.COM")
CanonicalEmails::Address.parse("Alex.Smith+Newsletter@GMAIL.COM")
CanonicalEmails::Downcase.parse("Alex.Smith+Newsletter@EXAMPLE.COM")
```

An explicit provider class rejects mismatched domains with `ArgumentError`, including empty and domainless input. `GMail.parse("alex@outlook.com")` raises rather than returning a misleading Gmail object. All `.parse` entry points return `nil` for nil input.

### Gmail Normalization

`CanonicalEmails::GMail` removes periods and the first `+` and everything after it from the local part, and lowercases the local part and domain. Display names are preserved. [Gmail period equivalence](https://support.google.com/mail/answer/7436150?hl=en) applies to `gmail.com`, not custom domains.

Generic addresses preserve local-part and domain casing for compatibility. Domains are case-insensitive; preserving their case is not an email requirement. Use `type: CanonicalEmails::Downcase` to lowercase both parts regardless of provider.

### Model Accessors

```ruby
class User
  include CanonicalEmails::Extensions

  attr_accessor :email
  canonical_email :email
end

user = User.new
user.email = "Alex Smith <Alex.Smith+Newsletter@gmail.com>"
user.canonical_email.class # CanonicalEmails::GMail
user.canonical_email.address # "alexsmith@gmail.com"
user.canonical_email.tag # "Newsletter"
```

Accessors parse the current value on every call and return `nil` for nil input. Use `canonical_email :email, type: CanonicalEmails::Address` to disable provider detection or select a custom class. Positional transformer arguments and multi-transform pipelines are no longer supported; compose behaviors on a single class instead.

### Custom Address Types

`CanonicalEmails::Address` performs no normalization by default. Include any combination of these mixins to opt in, without option flags:

| Mixin under `CanonicalEmails::Behaviors` | Behavior |
|---|---|
| `DowncaseLocal` | Lowercase the local part. |
| `DowncaseDomain` | Lowercase the domain. |
| `RemovePeriods` | Remove periods from the local part. |
| `StripTags` | Remove the first `+` and its suffix, storing the original suffix in `tag`. |

`GMail` includes all four. `Downcase` includes the two downcasing mixins. To normalize Gmail periods and case while retaining plus-tags:

```ruby
class TaggedGMail < CanonicalEmails::Address
  include CanonicalEmails::Behaviors::DowncaseLocal
  include CanonicalEmails::Behaviors::DowncaseDomain
  include CanonicalEmails::Behaviors::RemovePeriods

  def self.accepts?(domain)
    domain&.casecmp?("gmail.com")
  end
end

email = CanonicalEmails.parse("Alex.Smith+Newsletter@GMAIL.COM", type: TaggedGMail)
email.address # "alexsmith+newsletter@gmail.com"
email.username # "Alex.Smith+Newsletter"
email.tag # nil
```

Custom types are selected explicitly, not automatically registered for provider detection. Override `.accepts?(domain)` to restrict allowed domains; it receives the original parsed domain. Mixins otherwise apply to all domains. Only remove periods or tags where your application has established equivalence. A custom type works directly in a model: `canonical_email :email, type: TaggedGMail`.

The input is parsed once and passed as Mail's parsed address structure to the selected class, retaining original metadata without serialization between normalization steps.

### Validation

Canonicalization is not validation. Mail parsing may reject malformed input but also accepts forms without a domain. Provider class checks only enforce a domain restriction; they do not establish RFC compliance, DNS existence, mailbox ownership, or deliverability. Apply your application's validation policy separately and verify ownership with a confirmation email when needed.

### Contribute

See [CONTRIBUTING](CONTRIBUTING.md).

### Copyright and License

Copyright Daniel Doubrovkine and Contributors, [Artsy](https://artsy.net), 2013-2014

[MIT License](LICENSE.md)
