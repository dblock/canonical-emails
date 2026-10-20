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

Each accessor reads its own field without changing the original value. A nil field returns nil.

### Custom Accessor Names

Use `as:` to choose the generated accessor's name instead of `canonical_<field>`. String and symbol names are supported, and each field can have its own name and type:

```ruby
class User
  include CanonicalEmails::Extensions

  attr_accessor :email, :backup_email
  canonical_email :email, as: :normalized_email
  canonical_email :backup_email, as: :normalized_backup, type: CanonicalEmails::TaggedGMail
end

user = User.new
user.email = "Alex.Smith+Newsletter@gmail.com"
user.backup_email = "Alex.Smith+Backup@gmail.com"
user.normalized_email.address # "alexsmith@gmail.com"
user.normalized_backup.address # "alexsmith+backup@gmail.com"
```

Custom names replace the default generated names. When the name differs from the source field, the original reader and writer remain unchanged.

#### Override the Original Reader

Use the source field's name with `as:` to return a parsed address directly from that reader:

```ruby
class User
  include CanonicalEmails::Extensions

  attr_accessor :email
  canonical_email :email, as: :email
end

user = User.new
user.email = "Alex.Smith+Newsletter@gmail.com"
user.email.class # CanonicalEmails::GMail
user.email.address # "alexsmith@gmail.com"
user.email.tag # "Newsletter"
```

The reader now returns an address object (or `nil`) instead of a string. The original writer still stores the submitted value unchanged. The source reader must exist when accessed; inherited and generated readers are supported. `type:` also works with reader overrides.

Raw-value access depends on your model: for the `attr_accessor` example, `user.instance_variable_get(:@email)` returns the original string; in ActiveRecord, use `user[:email]`. No additional raw-value accessor is generated.

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

It enforces the same Gmail domain restrictions as `GMail`. `tag` remains `nil` because the suffix is not stripped.

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

See [Custom Address Types](#custom-address-types) for additional normalization behaviors.

Registrations match complete domains case-insensitively, not subdomains or suffixes. The type must subclass `Address` and accept the registered domain. Repeating the same mapping is harmless; a conflicting mapping raises `ArgumentError` without replacing the existing type. Explicit `type:` and class-level `.parse` bypass the registry.

Call `CanonicalEmails.clear` during application initialization to remove all registrations, including the default Gmail mapping, before configuring your own provider set. For example, to use `TaggedGMail` for automatic Gmail detection:

```ruby
CanonicalEmails.clear
CanonicalEmails.register("gmail.com", type: CanonicalEmails::TaggedGMail)

email = CanonicalEmails.parse("Alex.Smith+Newsletter@gmail.com")
email.class # CanonicalEmails::TaggedGMail
email.address # "alexsmith+newsletter@gmail.com"
```

Defaults are not automatically restored: domains remain generic until registered again. Explicit `type:` and class-level `.parse` continue to work. Configure the full provider set before serving requests.

### Explicit Types

Use `canonical_email :email, type: CanonicalEmails::Address` to disable provider detection in a model, or select another class with `type:`.

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

Generic addresses preserve local-part and domain casing. Use `type: CanonicalEmails::Downcase` to lowercase both parts regardless of provider.

### Assignment

#### Model Fields

Both separately named and overridden model readers cache their results per accessor and model instance. Each read compares the current raw input against a saved string copy, detecting writer assignments, changes that bypass the writer, and in-place string edits. Unchanged input returns the same address object (or cached nil); changed input is parsed again. Parsing errors propagate rather than returning a stale result. Configure provider registrations during initialization; registry changes alone do not invalidate existing model caches.

Canonical address objects do not support `address=`. Assign through the model's original writer instead:

```ruby
user.email = "Alex.Smith+Newsletter@gmail.com"
user.canonical_email.equal?(user.canonical_email) # true
user.canonical_email.address = "Alex@example.com" # raises NoMethodError
user.email = "Alex@example.com"
user.canonical_email.address # "Alex@example.com"
```

For `as: :email`, use `user.email = ...` to update the stored value. Removing `address=` does not make other inherited Mail APIs read-only.

#### Directly Parsed Addresses

Parse a new value instead of reassigning a directly parsed address:

```ruby
email = CanonicalEmails.parse("Alex.Smith@gmail.com")
email = CanonicalEmails.parse("Alex Smith <Alex.Smith+Newsletter@GMAIL.COM>")
email.to_s # "Alex Smith <alexsmith@gmail.com>"
email.username # "Alex.Smith+Newsletter"
email.tag # "Newsletter"
```

### Custom Address Types

`CanonicalEmails::Address` performs no normalization by default. Include any combination of these mixins to opt in:

| Mixin under `CanonicalEmails::Behaviors` | Behavior |
|---|---|
| `DowncaseLocal` | Lowercase the local part. |
| `DowncaseDomain` | Lowercase the domain. |
| `RemovePeriods` | Remove periods from the local part. |
| `StripTags` | Remove the first `+` and its suffix, storing the original suffix in `tag`. |

`Downcase` includes the two downcasing mixins for all domains. `TaggedGMail` composes both downcasing mixins and `RemovePeriods`; `GMail` adds `StripTags`.

Custom types are not automatically registered for provider detection. Override `.accepts?(domain)` to restrict allowed domains; it receives the original parsed domain. Mixins otherwise apply to all domains. Only remove periods or tags where your application has established equivalence. A custom type works directly in a model: `canonical_email :email, type: CustomAddress`.

### Validation

CanonicalEmails normalizes email addresses; it does not validate them. For Active Model email validations, consider [valid_email](https://github.com/hallelujah/valid_email), configured separately.

### Contribute

See [CONTRIBUTING](CONTRIBUTING.md).

### Copyright and License

Copyright Daniel Doubrovkine and Contributors, [Artsy](https://artsy.net), 2013-2014

[MIT License](LICENSE.md)
