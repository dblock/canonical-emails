# Releasing CanonicalEmails

This workflow follows [ActionMailer::Text](https://github.com/dblock/actionmailer-text/blob/master/RELEASING.md) and [Ruby-Enum](https://github.com/dblock/ruby-enum/blob/master/RELEASING.md). Publishing requires repository push access and RubyGems ownership with MFA enabled. Never commit credentials or OTP codes.

## Prepare

Start from a clean, current master using a Ruby compatible with the ActiveSupport version in Gemfile:

```sh
git checkout master
git pull --ff-only origin master
bundle install
bundle exec rake
```

Confirm [CI](https://github.com/dblock/canonical-emails/actions/workflows/ci.yml) passes across the full Ruby/ActiveSupport matrix. Follow [Semantic Versioning](https://semver.org/); during the initial 0.x series, increment the minor version for breaking changes and describe them explicitly.

Ensure `lib/canonical-emails/version.rb` matches the upcoming CHANGELOG.md section. Replace `Next` with a date in `YYYY-MM-DD` format, remove the contribution placeholder from that section, and review compatibility changes. Submit and merge a release-preparation PR before publishing:

```sh
git checkout -b release/0.2.0
git add CHANGELOG.md lib/canonical-emails/version.rb
git commit -m "Prepare release 0.2.0"
git push -u origin release/0.2.0
```

Use the intended version in place of 0.2.0 throughout this guide. After merging, update master and confirm the release commit's CI is green. Build and inspect the package:

```sh
git checkout master
git pull --ff-only origin master
bundle exec rake build
tar -xOf pkg/canonical-emails-0.2.0.gem data.tar.gz | tar -tzf -
```

The package should contain library files and published documentation, not specs, credentials, or local artifacts.

## Publish and Verify

From the clean release commit:

```sh
bundle exec rake release
```

Bundler builds the gem, tags `v0.2.0`, pushes commits/tags, and publishes to RubyGems.org. Complete MFA as prompted.

If only the upload fails, first check whether the version is already published. Do not move a pushed tag or rerun the release task blindly. Retry just the existing package upload if necessary:

```sh
gem push pkg/canonical-emails-0.2.0.gem
```

Verify [RubyGems](https://rubygems.org/gems/canonical-emails) and the tag's commit:

```sh
gem list --remote --exact canonical-emails
git ls-remote --tags origin 'v0.2.0*'
```

Create a [GitHub release](https://github.com/dblock/canonical-emails/releases) from the existing tag using that version's changelog entries. A GitHub release does not publish the gem to RubyGems.

## Next Development Version

In a separate PR, increment the patch version in `lib/canonical-emails/version.rb` and prepend:

```markdown
### 0.2.1 (Next)

* Your contribution here.
```

```sh
git checkout -b chore/prepare-0.2.1
git add CHANGELOG.md lib/canonical-emails/version.rb
git commit -m "Prepare next development version 0.2.1"
git push -u origin chore/prepare-0.2.1
```
