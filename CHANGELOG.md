### 0.2.0 (Next)

* [#15](https://github.com/dblock/canonical-emails/pull/15): Cache canonical model accessors by raw field value and remove `address=` from all canonical address types - [@dblock](https://github.com/dblock).
* [#14](https://github.com/dblock/canonical-emails/pull/14): Add `as:` for custom canonical email accessor names and optional original-reader overrides - [@dblock](https://github.com/dblock).
* [#13](https://github.com/dblock/canonical-emails/pull/13): Document and test independent canonical accessors for multiple email fields - [@dblock](https://github.com/dblock).
* [#12](https://github.com/dblock/canonical-emails/pull/12): Add explicit, case-insensitive provider registration, registry clearing, and an unregistered `TaggedGMail` type that retains plus-tags - [@dblock](https://github.com/dblock).
* [#11](https://github.com/dblock/canonical-emails/pull/11): Introduce breaking provider-aware `.parse` and `type:` APIs, replace nested provider address classes and transform pipelines, and enforce provider restrictions on address reassignment; see UPGRADING.md - [@dblock](https://github.com/dblock).
* [#10](https://github.com/dblock/canonical-emails/pull/10): Refactor provider transformations into a shared address subclass with opt-in behavior mixins and document migration in UPGRADING.md - [@dblock](https://github.com/dblock).
* [#6](https://github.com/dblock/canonical-emails/pull/6): Add release and agent guides and prepare version 0.2.0 - [@dblock](https://github.com/dblock).

* [#8](https://github.com/dblock/canonical-emails/pull/8): Add Danger checks with danger-changelog - [@dblock](https://github.com/dblock).
* [#7](https://github.com/dblock/canonical-emails/pull/7): Add line and branch coverage reporting with SimpleCov and Coveralls - [@dblock](https://github.com/dblock).
* [#5](https://github.com/dblock/canonical-emails/pull/5): Canonicalize Gmail plus-address tags and expose the original `username` and `tag` through `CanonicalEmails::GMail::Address`, adapted from [#3](https://github.com/dblock/canonical-emails/pull/3) - [@jdpopkin](https://github.com/jdpopkin).
* [#4](https://github.com/dblock/canonical-emails/pull/4): Replace Travis CI with GitHub Actions for Ruby 3.1–4.0 and ActiveSupport 6.1–8.1, require Ruby 3.1, and modernize development dependencies and lint configuration - [@dblock](https://github.com/dblock).
* Your contribution here.
* Implemented RuboCop, Ruby style linter - [@dblock](https://github.com/dblock).
* Upgraded RSpec to 3.x syntax - [@dblock](https://github.com/dblock).

### 0.1.0 (2013-06-22)

* Initial public release, written on a plane from NYC to SF - [@dblock](https://github.com/dblock).
