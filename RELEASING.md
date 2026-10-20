# Releasing CanonicalEmails

This workflow follows [ActionMailer::Text](https://github.com/dblock/actionmailer-text/blob/master/RELEASING.md) and [Ruby-Enum](https://github.com/dblock/ruby-enum/blob/master/RELEASING.md). Publishing requires repository push access and RubyGems ownership with MFA enabled. Never commit credentials or OTP codes.

## Prepare

Start from a clean, current master using a Ruby compatible with the ActiveSupport version in Gemfile:

```sh
git checkout master
git pull --ff-only origin master
```

Install dependencies if needed. Run `bundle exec rake` once immediately before committing the release preparation.

Confirm [CI](https://github.com/dblock/canonical-emails/actions/workflows/ci.yml) passes across the full Ruby/ActiveSupport matrix. Follow [Semantic Versioning](https://semver.org/); during the initial 0.x series, increment the minor version for breaking changes and describe them explicitly.

Ensure `lib/canonical-emails/version.rb` matches the upcoming CHANGELOG.md section. Replace `Next` with a date in `YYYY-MM-DD` format, remove the contribution placeholder and extra blank lines within the release's list, and review compatibility changes. Commit and push directly on master; no release-preparation PR is needed:

```sh
bundle exec rake
git add CHANGELOG.md lib/canonical-emails/version.rb
git commit -m "Prepare release 0.2.0"
git push origin master
```

Use the intended version in place of 0.2.0 throughout this guide. Confirm the release commit's CI is green. Build and inspect the package from the clean release commit:

```sh
bundle exec rake build
tar -xOf pkg/canonical-emails-0.2.0.gem data.tar.gz | tar -tzf -
```

The package should contain library files and published documentation, not specs, credentials, or local artifacts.

## Publish and Verify

Ask the maintainer for a fresh RubyGems OTP immediately before publishing. Never store it in files or commit it. Publish the inspected package, entering the OTP when prompted:

```sh
gem push pkg/canonical-emails-0.2.0.gem
```

If the upload fails or its result is unclear, check whether the version is already published before retrying the existing package. Verify the exact version using the RubyGems API; remote gem listings may lag:

```sh
curl --fail --silent --show-error https://rubygems.org/api/v2/rubygems/canonical-emails/versions/0.2.0.json
```

After successful publication, create and push the release tag. Never move an existing pushed tag:

```sh
git tag -a v0.2.0 -m "Version 0.2.0"
git push origin v0.2.0
git ls-remote --tags origin 'v0.2.0*'
```

Create a [GitHub release](https://github.com/dblock/canonical-emails/releases) from that tag using only that version's changelog entries, not the entire changelog. Verify the published gem version, tag commit, and GitHub release before continuing. A GitHub release does not publish the gem to RubyGems.

## Next Development Version

Complete the release by incrementing the patch version in `lib/canonical-emails/version.rb` and prepending the matching changelog section:

```markdown
### 0.2.1 (Next)

* Your contribution here.
```

```sh
bundle exec rake
git add CHANGELOG.md lib/canonical-emails/version.rb
git commit -m "Prepare next development version 0.2.1"
git push origin master
```

Commit this directly on master, without a PR or a new release tag. Leave master clean and ready for development.
