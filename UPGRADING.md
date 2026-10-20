# Upgrading CanonicalEmails

## From 0.1.x to 0.2.0

Version 0.2.0 requires Ruby 3.1 or newer. Choose Mail and ActiveSupport versions compatible with your Ruby version; the CI matrix exercises ActiveSupport 6.1 through 8.1 on Ruby 3.1 through 4.0. This is not a requirement to upgrade your application to ActiveSupport 8.1.

Both entry points remain supported:

```ruby
require 'canonical-emails'
# Or: require 'canonical_emails'
```

### Gmail plus-tags now canonicalize to the base mailbox

`CanonicalEmails::GMail` continues to remove periods and lowercase the local part and domain for `gmail.com`, matched case-insensitively. It now also removes the first `+` and everything after it from the local part.

```ruby
email = CanonicalEmails::GMail.transform("Donald Duck <Donald.Duck+News+Offers@GMAIL.COM>")
email.to_s # => "Donald Duck <donaldduck@gmail.com>"
email.address # => "donaldduck@gmail.com"
email.local # => "donaldduck"
email.username # => "Donald.Duck+News+Offers"
email.tag # => "News+Offers"
```

`username` preserves the original local part, including case, periods, and plus-tags. `tag` preserves the removed suffix, including case and additional `+` characters. Both are read-only properties and refresh when `email.address` is reassigned. A missing tag returns `nil`; an explicitly empty tag (`donald.duck+@gmail.com`) returns `""`.

**Review stored canonical addresses and uniqueness constraints before upgrading.** Addresses such as `donald.duck+work@gmail.com` and `donaldduck@gmail.com` now produce the same canonical value. Plan how to handle existing collisions before backfilling canonical fields or rebuilding unique indexes. Preserve the submitted address separately if your application needs it for delivery or auditing; a later parse of the canonical string cannot recover the original username or tag.

Other domains remain unchanged by `GMail`, including local-part and domain casing. Gmail rules do not apply to Google Workspace custom domains or Outlook addresses. No Outlook transformer is provided: we do not assume that periods or plus-tags identify equivalent Outlook mailboxes.

### Returned addresses are subclasses of Mail::Address

The built-in transformers now use a shared `CanonicalEmails::Address < Mail::Address` base instead of per-instance method patches:

| Transformer | Returned class |
|---|---|
| `CanonicalEmails::GMail` | `CanonicalEmails::GMail::Address` |
| `CanonicalEmails::Downcase` | `CanonicalEmails::Downcase::Address` |

Existing `.transform`, `.local`, `.domain`, `.address`, `.name`, and `.to_s` calls remain available. Replace exact class checks such as `email.class == Mail::Address` with `email.is_a?(Mail::Address)` when testing compatibility with Mail.

`Downcase` still lowercases both the local part and domain for any provider. Existing nil handling is retained: `Downcase.transform(nil)` returns `nil`, whereas `GMail.transform(nil)` returns an empty address. Display names are preserved.

### Normalization behaviors are opt-in mixins

`CanonicalEmails::Address` performs no normalization by default. Custom subclasses opt in by including mixins under `CanonicalEmails::Behaviors`:

| Mixin | Behavior |
|---|---|
| `DowncaseLocal` | Lowercase the local part. |
| `DowncaseDomain` | Lowercase the domain. |
| `RemovePeriods` | Remove periods from the local part. |
| `StripTags` | Remove the first `+` and its suffix, storing the original suffix in `tag`. |

`GMail::Address` includes all four, restricted to `gmail.com`. `Downcase::Address` includes the two downcasing mixins for all domains. There are no normalization option flags.

If your application intentionally distinguishes Gmail plus-addresses, define a transformer without `StripTags`:

```ruby
class TaggedGMail < CanonicalEmails::Address
  include CanonicalEmails::Behaviors::DowncaseLocal
  include CanonicalEmails::Behaviors::DowncaseDomain
  include CanonicalEmails::Behaviors::RemovePeriods

  private

  def normalize?
    get_domain&.casecmp?("gmail.com")
  end
end

email = TaggedGMail.transform("Donald.Duck+News@GMAIL.COM")
email.address # => "donaldduck+news@gmail.com"
email.username # => "Donald.Duck+News"
email.tag # => nil
```

Mixins apply to all domains unless the subclass overrides the private `normalize?` predicate. Use the original parsed domain (`get_domain`) inside that predicate, not the transformed `domain` method, to avoid recursion. Only remove periods or tags for domains where your application has established equivalence.

### Model accessors and custom transformers

The model API and left-to-right transformation order are unchanged. Existing custom transformers that respond to `.transform` and return a `Mail::Address` remain supported. New address subclasses inherit `.transform` and can be passed directly:

```ruby
canonical_email :email, TaggedGMail
```

Each step receives the previous step's string representation, not its address object. Consequently, `username` and `tag` reflect the input to the last transformer, not necessarily the originally submitted address. Avoid reparsing a normalized address when you need its original metadata.

Canonicalization still does not verify mailbox ownership or deliverability. Keep application validation and email confirmation separate.
