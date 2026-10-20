# Upgrading CanonicalEmails

## From 0.1.x to 0.2.0

Requires Ruby 3.1 or newer. Both `require 'canonical-emails'` and `require 'canonical_emails'` remain supported.

### Replace transform with parse

Names below are relative to `CanonicalEmails`.

| Before | After |
|---|---|
| `GMail.transform(value)` | `CanonicalEmails.parse(value)` |
| `Downcase.transform(value)` | `Downcase.parse(value)` |
| `canonical_email :email, GMail` | `canonical_email :email` |
| `canonical_email :email, Downcase` | `canonical_email :email, type: Downcase` |
| `email.class == Mail::Address` | `email.is_a?(Mail::Address)` |

`GMail` and `Downcase` are now subclasses of `CanonicalEmails::Address < Mail::Address`. Automatic parsing selects `GMail` only for `gmail.com`; other domains return an unchanged `Address`. Explicit `GMail.parse` rejects other domains with `ArgumentError`.

### Gmail plus-tags are removed

```ruby
# Before
CanonicalEmails::GMail.transform("Alex.Smith+Newsletter@gmail.com").address
# => "alexsmith+newsletter@gmail.com"

# After
email = CanonicalEmails.parse("Alex.Smith+Newsletter@gmail.com")
email.address # => "alexsmith@gmail.com"
email.username # => "Alex.Smith+Newsletter"
email.tag # => "Newsletter"

# To retain plus-tags
CanonicalEmails::TaggedGMail.parse("Alex.Smith+Newsletter@gmail.com").address
# => "alexsmith+newsletter@gmail.com"
```

**Check stored canonical addresses and unique indexes for collisions before backfilling.** Previously distinct Gmail values may now canonicalize to the same address.

### Handle nil and reject non-string input

| Before | After |
|---|---|
| `GMail.transform(nil)` returns an empty address | `CanonicalEmails.parse(nil)` returns `nil` |
| Model accessors stringify input before transformation | Input must be a String or nil; other types raise `TypeError` |

```ruby
# Before
user.canonical_email.address

# After: the source field may be nil
user.canonical_email&.address
```

Empty and domainless strings remain generic addresses with default parsing. Mail parsing errors propagate.

### Replace address assignment

`address=` has been removed and raises `NoMethodError`.

```ruby
# Before
email.address = "Alex@example.com"

# After: standalone address
email = CanonicalEmails.parse("Alex@example.com")

# After: model field
user.email = "Alex@example.com"
user.canonical_email.address # => "Alex@example.com"
```

Model readers now return the same parsed object while the raw field value is unchanged, including nil results. Assignments and in-place string edits refresh the cache; provider registry changes alone do not.

### Replace transformer pipelines with one address type

```ruby
# Before: custom transformers applied in sequence
canonical_email :email, RemovePeriods, CanonicalEmails::Downcase

# After: select one class with the required behaviors
class CustomAddress < CanonicalEmails::Address
  include CanonicalEmails::Behaviors::RemovePeriods
  include CanonicalEmails::Behaviors::DowncaseLocal
  include CanonicalEmails::Behaviors::DowncaseDomain
end

canonical_email :email, type: CustomAddress
```

Move custom `.transform` logic into address subclasses or behavior mixins. Restrict provider-specific rules with `.accepts?(domain)` and register types during initialization for automatic dispatch. See [Custom Address Types](README.md#custom-address-types) and [Register Providers](README.md#register-providers).
