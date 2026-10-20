# Upgrading CanonicalEmails

## From 0.1.x to 0.2.0

Version 0.2.0 requires Ruby 3.1 or newer. Choose Mail and ActiveSupport versions compatible with your Ruby version; CI exercises ActiveSupport 6.1 through 8.1 on Ruby 3.1 through 4.0. Applications are not required to upgrade to ActiveSupport 8.1.

Both `require 'canonical-emails'` and `require 'canonical_emails'` remain supported.

### Replace transform with parse

`.transform` has been removed. Use `CanonicalEmails.parse(value)` for automatic provider detection, or `type:` to request an exact class:

| Previous API | Replacement |
|---|---|
| `GMail.transform(value)` | `CanonicalEmails.parse(value)` to normalize Gmail and leave other domains unchanged |
| `Downcase.transform(value)` | `CanonicalEmails.parse(value, type: CanonicalEmails::Downcase)` |
| `Address.transform(value)` | `CanonicalEmails.parse(value, type: CanonicalEmails::Address)` |
| `canonical_email :email, GMail` | `canonical_email :email` |
| `canonical_email :email, Downcase` | `canonical_email :email, type: CanonicalEmails::Downcase` |

Names in the previous-API column are relative to `CanonicalEmails`.

`CanonicalEmails::GMail` and `CanonicalEmails::Downcase` are now classes inheriting from `CanonicalEmails::Address < Mail::Address`, not modules with nested `Address` classes. Replace references to `GMail::Address` and `Downcase::Address` with `GMail` and `Downcase`. Replace exact checks such as `email.class == Mail::Address` with `email.is_a?(Mail::Address)` where appropriate.

### Provider detection and explicit types

Automatic detection returns `CanonicalEmails::GMail` only for `gmail.com`, matched case-insensitively. Every other domain returns a generic `CanonicalEmails::Address` with no normalization, including Outlook, `googlemail.com`, and Google Workspace custom domains. A non-Gmail address is never wrapped in a Gmail object.

Specifying `type:` disables automatic detection and requests that exact class. `GMail.parse(value)` is shorthand for `CanonicalEmails.parse(value, type: CanonicalEmails::GMail)` and raises `ArgumentError` for non-Gmail domains, empty strings, and domainless input. Direct construction with `GMail.new` also enforces the domain restriction.

Use `type: CanonicalEmails::Address` to preserve an address unchanged even if it belongs to Gmail, or `type: CanonicalEmails::Downcase` to lowercase both parts for any provider without removing periods or tags. Invalid types raise `ArgumentError`.

### Nil, empty, and mutable input

Every `.parse` entry point now returns `nil` for nil input. Previously `GMail.transform(nil)` returned an empty address, so callers must handle nil consistently. Default parsing of an empty or whitespace-only string returns an empty generic address; domainless input remains generic. Input must be a String or nil; other values raise `TypeError` instead of being silently stringified by model accessors. Mail parsing errors propagate.

`address=` remains supported and refreshes normalization, `username`, `tag`, and cached display-name/comment formatting. It retains the object's class and enforces that class's provider restriction. Assigning a non-Gmail, empty, or nil value to a Gmail object raises `ArgumentError`, leaving its existing address and metadata unchanged. Generic addresses can be cleared with nil or an empty string. Invalid input types and parsing errors also leave the object unchanged.

```ruby
email = CanonicalEmails.parse("Alex@gmail.com")
email.address = "Alex.Smith+Newsletter@GMAIL.COM"
email.tag # => "Newsletter"
# To change providers, parse a new object:
email = CanonicalEmails.parse("Alex@EXAMPLE.COM")
email.class # => CanonicalEmails::Address
```

### Gmail plus-tags now canonicalize to the base mailbox

Gmail still removes periods and lowercases both parts. It now also removes the first `+` and everything after it from the local part:

```ruby
email = CanonicalEmails.parse("Alex Smith <Alex.Smith+Newsletter+Offers@GMAIL.COM>")
email.to_s # => "Alex Smith <alexsmith@gmail.com>"
email.address # => "alexsmith@gmail.com"
email.username # => "Alex.Smith+Newsletter+Offers"
email.tag # => "Newsletter+Offers"
```

The read-only `username` preserves the original local part. `tag` preserves the removed suffix, including case and additional `+` characters. Missing tags return `nil`; an explicitly empty Gmail tag (`alex.smith+@gmail.com`) returns `""`. Generic addresses have `tag == nil`.

**Review stored canonical addresses and uniqueness constraints before upgrading.** `alex.smith+work@gmail.com` and `alexsmith@gmail.com` now produce the same canonical value. Resolve existing collisions before backfilling canonical fields or rebuilding unique indexes. Preserve the submitted address separately if needed for delivery or auditing; reparsing a canonical string cannot recover its original metadata.

### Replace pipelines with behavior composition

Positional transformer lists and `.transform`-based custom transformers are no longer supported by model accessors. The old pipeline serialized and reparsed each step, losing original metadata. Define one address subclass with the desired mixins and select it using `type:`:

```ruby
class TaggedGMail < CanonicalEmails::Address
  include CanonicalEmails::Behaviors::DowncaseLocal
  include CanonicalEmails::Behaviors::DowncaseDomain
  include CanonicalEmails::Behaviors::RemovePeriods

  def self.accepts?(domain)
    domain&.casecmp?("gmail.com")
  end
end

canonical_email :email, type: TaggedGMail
```

This example retains plus-tags in the normalized address because it omits `StripTags`. Available mixins are `DowncaseLocal`, `DowncaseDomain`, `RemovePeriods`, and `StripTags`; there are no option flags. Custom types inherit `.parse` and must subclass `CanonicalEmails::Address`. Override `.accepts?` to reject unsupported domains; otherwise the base accepts all domains. Custom types are not automatically registered for provider dispatch.

`username` and `tag` are captured from the original parsed input rather than a previous transformer's serialized output. If a custom transformer previously patched Mail internals, move that behavior into a subclass or mixin while preserving method argument signatures and return contracts. [README.md](README.md) documents the composition API.

### Provider boundaries and validation

Generic addresses preserve local-part and domain casing for compatibility, not because domains are case-sensitive. Gmail rules are not applied to other domains. No Outlook transformer or period/plus-tag equivalence is assumed.

Canonicalization and domain restrictions do not verify mailbox ownership or deliverability. Keep application validation and email confirmation separate.
