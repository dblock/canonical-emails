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

### Basic Usage

Add a canonical email accessor to your model:

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

### Multiple Email Fields

Declare `canonical_email` once for each field. Each declaration creates a separate `canonical_<field>` accessor and can select its own `type:`:

```ruby
class User
  include CanonicalEmails::Extensions

  attr_accessor :email, :backup_email
  canonical_email :email
  canonical_email :backup_email, type: CanonicalEmails::TaggedGMail
end

user = User.new
user.email = "Alex.Smith+Newsletter@gmail.com"
user.backup_email = "Alex.Smith+Backup@gmail.com"
user.canonical_email.address # "alexsmith@gmail.com"
user.canonical_backup_email.address # "alexsmith+backup@gmail.com"
```

The accessors are independent: each parses its own field's current value without changing either original field. Updating or clearing one field does not affect the other; a nil field produces a nil canonical accessor.

### Parse

To parse an address directly without a model, use `CanonicalEmails.parse`:

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

Provider detection matches the complete domain case-insensitively. Unregistered domains return generic addresses. See [Available Providers](#available-providers) for built-in behavior and [Register Providers](#register-providers) for adding your own types.

`parse(nil)` returns `nil`. Empty or whitespace-only strings return empty generic addresses. Domainless input remains a generic address. Non-string input raises `TypeError`; malformed input may raise Mail parsing errors.

The read-only `username` property preserves the original local part, including case, periods, and plus-tags. `tag` preserves the removed suffix, including case and additional `+` characters, when tag stripping is enabled. A missing tag returns `nil`; an explicitly empty tag returns `""`. Generic addresses have `tag == nil`.

### Available Providers

#### Gmail

`CanonicalEmails::GMail` is the default Gmail provider type. It registers `gmail.com` through the same registration API available to applications, matching the complete domain case-insensitively. Outlook, `googlemail.com`, and Google Workspace custom domains remain generic unless your application registers them.

Gmail normalization removes periods and the first `+` and everything after it from the local part, and lowercases the local part and domain. Display names are preserved. [Gmail period equivalence](https://support.google.com/mail/answer/7436150?hl=en) applies to `gmail.com`, not custom domains.

```ruby
email = CanonicalEmails::GMail.parse("Alex Smith <Alex.Smith+Newsletter+Offers@GMAIL.COM>")
email.class # CanonicalEmails::GMail
email.to_s # "Alex Smith <alexsmith@gmail.com>"
email.address # "alexsmith@gmail.com"
email.username # "Alex.Smith+Newsletter+Offers"
email.tag # "Newsletter+Offers"
```

`username` retains the original local part, and `tag` retains the original plus suffix. An explicitly empty Gmail tag (`alex.smith+@gmail.com`) returns `""`; no plus sign returns `nil`.

Explicit parsing with `GMail.parse("alex@outlook.com")` raises `ArgumentError` rather than returning a misleading Gmail object. Gmail objects also reject non-Gmail, empty, and nil assignments, leaving the existing address unchanged. Parse a new object to change providers.

```ruby
CanonicalEmails::GMail.parse("alex.smith+@gmail.com").tag # ""
CanonicalEmails::GMail.parse("alex.smith@gmail.com").tag # nil
CanonicalEmails::GMail.parse("alex@outlook.com") # raises ArgumentError
```

#### Tagged Gmail

`CanonicalEmails::TaggedGMail` normalizes Gmail periods and case while retaining the complete plus suffix in the address, lowercased along with the rest of the local part. It is built in but not registered for automatic dispatch; select it explicitly:

```ruby
email = CanonicalEmails::TaggedGMail.parse("Alex Smith <Alex.Smith+Newsletter+Offers@GMAIL.COM>")
email.class # CanonicalEmails::TaggedGMail
email.to_s # "Alex Smith <alexsmith+newsletter+offers@gmail.com>"
email.address # "alexsmith+newsletter+offers@gmail.com"
email.username # "Alex.Smith+Newsletter+Offers"
email.tag # nil
```

It enforces the same Gmail domain restrictions as `GMail`. `tag` remains `nil` because the suffix is not stripped. `GMail` inherits its normalization from `TaggedGMail` and adds `StripTags`; default parsing continues to return `GMail`.

### Register Providers

Register a custom class during application initialization to enable automatic selection in both `CanonicalEmails.parse` and model accessors. For example, an application can define an Outlook type that lowercases the domain while preserving the local part, periods, and plus-tags:

```ruby
class Outlook < CanonicalEmails::Address
  include CanonicalEmails::Behaviors::DowncaseDomain

  def self.accepts?(domain)
    domain&.casecmp?("outlook.com")
  end
end

CanonicalEmails.register("outlook.com", type: Outlook)
email = CanonicalEmails.parse("Alex.Smith+Newsletter@OUTLOOK.COM")
email.class # Outlook
email.address # "Alex.Smith+Newsletter@outlook.com"
email.username # "Alex.Smith+Newsletter"
email.tag # nil
```

To implement additional normalization, include the corresponding mixins in your custom class: `DowncaseLocal` for local-part case, `RemovePeriods` for periods, or `StripTags` for plus-tags. `StripTags` also populates `tag` from the original suffix. Enable period or tag removal only after establishing that those variants identify the same mailbox for the provider and deployment you support; adding an Outlook class alone does not establish that guarantee.

Registrations match complete domains case-insensitively, not subdomains or suffixes. The type must subclass `Address` and accept the registered domain. Repeating the same mapping is harmless; a conflicting mapping raises `ArgumentError` without replacing the existing type. Explicit `type:` and class-level `.parse` bypass the registry. Registration and lookup are synchronized; configure providers during initialization before serving requests. There is no automatic subclass discovery or load-order-based provider precedence.

The input is parsed once and passed as Mail's parsed address structure to the selected class, retaining original metadata without serialization between normalization steps.

Call `CanonicalEmails.clear` during application initialization to remove all registrations, including the default Gmail mapping, before configuring your own provider set. For example, to use `TaggedGMail` for automatic Gmail detection:

```ruby
CanonicalEmails.clear
CanonicalEmails.register("gmail.com", type: CanonicalEmails::TaggedGMail)

email = CanonicalEmails.parse("Alex.Smith+Newsletter@gmail.com")
email.class # CanonicalEmails::TaggedGMail
email.address # "alexsmith+newsletter@gmail.com"
```

Clearing an empty registry is harmless. Defaults are not automatically restored: domains remain generic until registered again. Explicit `type:` and class-level `.parse` continue to work. `clear` is synchronized, but clearing and registering are separate operations; configure the full set before serving requests.

### Explicit Types

Model accessors parse the current value on every call and return `nil` for nil input. Use `canonical_email :email, type: CanonicalEmails::Address` to disable provider detection or select a custom class. Positional transformer arguments and multi-transform pipelines are no longer supported; compose behaviors on a single class instead.

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

An explicit provider class rejects mismatched domains with `ArgumentError`, including empty and domainless input. All `.parse` entry points return `nil` for nil input.

Generic addresses preserve local-part and domain casing for compatibility. Domains are case-insensitive; preserving their case is not an email requirement. Use `type: CanonicalEmails::Downcase` to lowercase both parts regardless of provider.

### Assignment

Assign a new string with `email.address = value` to refresh normalization, `username`, `tag`, and cached display-name/comment formatting:

```ruby
email = CanonicalEmails.parse("Alex.Smith@gmail.com")
email.address = "Alex Smith <Alex.Smith+Newsletter@GMAIL.COM>"
email.to_s # "Alex Smith <alexsmith@gmail.com>"
email.username # "Alex.Smith+Newsletter"
email.tag # "Newsletter"
```

The object's class stays the same, and provider restrictions still apply. Rejected assignments leave the existing address unchanged. Generic addresses accept any domain and can be cleared with nil or an empty string. To auto-detect a different provider, call `CanonicalEmails.parse` again instead:

```ruby
email.address = "Alex.Smith@EXAMPLE.COM" # raises ArgumentError; email is unchanged
email = CanonicalEmails.parse("Alex.Smith@EXAMPLE.COM")
email.class # CanonicalEmails::Address
email.address # "Alex.Smith@EXAMPLE.COM"
```

### Custom Address Types

`CanonicalEmails::Address` performs no normalization by default. Include any combination of these mixins to opt in, without option flags:

| Mixin under `CanonicalEmails::Behaviors` | Behavior |
|---|---|
| `DowncaseLocal` | Lowercase the local part. |
| `DowncaseDomain` | Lowercase the domain. |
| `RemovePeriods` | Remove periods from the local part. |
| `StripTags` | Remove the first `+` and its suffix, storing the original suffix in `tag`. |

`Downcase` includes the two downcasing mixins for all domains. `TaggedGMail` composes both downcasing mixins and `RemovePeriods`; `GMail` adds `StripTags`.

Custom types are not automatically registered for provider detection. Override `.accepts?(domain)` to restrict allowed domains; it receives the original parsed domain. Mixins otherwise apply to all domains. Only remove periods or tags where your application has established equivalence. A custom type works directly in a model: `canonical_email :email, type: CustomAddress`.

### Validation

Canonicalization is not validation. Mail parsing may reject malformed input but also accepts forms without a domain. Provider class checks only enforce a domain restriction; they do not establish RFC compliance, DNS existence, mailbox ownership, or deliverability. Apply your application's validation policy separately and verify ownership with a confirmation email when needed.

### Contribute

See [CONTRIBUTING](CONTRIBUTING.md).

### Copyright and License

Copyright Daniel Doubrovkine and Contributors, [Artsy](https://artsy.net), 2013-2014

[MIT License](LICENSE.md)
