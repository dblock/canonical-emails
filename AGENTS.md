# Agent Guide

CanonicalEmails transforms email addresses using Mail::Address and provides ActiveSupport model extensions. Read [CONTRIBUTING.md](CONTRIBUTING.md) for setup and testing, and [RELEASING.md](RELEASING.md) for releases. Do not publish a gem or release tag without an explicit release request.

## Layout and Behavior

`lib/canonical-emails.rb` is the main entry point; `lib/canonical_emails.rb` is its underscore alias. `CanonicalEmails.parse` dispatches to an address class or honors an explicit `type:`. `Address` subclasses compose opt-in mixins from `Behaviors`; provider restrictions use class-level `.accepts?` against the original parsed domain. `extensions.rb` defines model accessors with the same type contract. Specs use YAML fixtures under `spec/canonical-emails/fixtures/`.

Preserve display names and original metadata. Gmail-specific classes must reject other domains. Parse input once; do not serialize between behaviors. All parsing entry points return nil for nil input. `address=` refreshes metadata and cached formatting, retains the class, and must reject invalid/provider-mismatched input without mutation. Parse a new object to change providers. This gem canonicalizes addresses; it does not verify mailbox ownership or deliverability.

Overrides of Mail methods must preserve their argument signatures and return contracts. Test complete address serialization as well as local/domain fields.

## Validation and Documentation

Use `bundle exec rake` for lint and specs before committing. Run focused specs while developing; see CONTRIBUTING.md for selecting ActiveSupport versions. Keep the Ruby minimum and CI matrix aligned.

Apply RuboCop autocorrections and review them before regenerating `.rubocop_todo.yml`. Metrics and Layout/LineLength are disabled. Remaining method-name exceptions preserve Mail's API.

Document public behavior in README.md and add a linked PR entry under the next release in CHANGELOG.md. Keep Markdown paragraphs on one line. The version lives in `lib/canonical-emails/version.rb`; align it with the upcoming changelog heading. Do not commit Gemfile.lock, coverage reports, or generated gem packages.
