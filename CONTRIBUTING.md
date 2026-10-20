# Contributing to Canonical-Emails

You're encouraged to submit [pull requests](https://github.com/dblock/canonical-emails/pulls), [propose features and discuss issues](https://github.com/dblock/canonical-emails/issues).

In the examples below, substitute your Github username for `contributor` in URLs.

## Fork the Project

Fork the [project on Github](https://github.com/dblock/canonical-emails) and check out your copy.

```
git clone https://github.com/contributor/canonical-emails.git
cd canonical-emails
git remote add upstream https://github.com/dblock/canonical-emails.git
```

## Create a Topic Branch

Make sure your fork is up-to-date and create a topic branch for your feature or bug fix.

```
git checkout master
git pull upstream master
git checkout -b my-feature-branch
```

## Bundle Install and Test

Ensure that you can build the project and run tests.

```
bundle install
bundle exec rake
```

Requires Ruby 3.1 or newer; use a Ruby compatible with the ActiveSupport version selected in Gemfile (8.1 by default). GitHub Actions tests ActiveSupport 6.1 through 8.1 with Ruby 3.1 through 4.0 and runs lint separately.

Select another ActiveSupport series with `ACTIVESUPPORT_VERSION`:

```sh
ACTIVESUPPORT_VERSION='~> 7.2.0' bundle update
ACTIVESUPPORT_VERSION='~> 7.2.0' bundle exec rspec
```

Run focused specs with `bundle exec rspec spec/canonical-emails/gmail_spec.rb`. Run `bundle exec rake` for RuboCop and the full suite. Metrics and line-length cops are disabled; regenerate `.rubocop_todo.yml` only after applying autocorrections and reviewing the remaining offenses.

## Write Tests

Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build.
Add to [spec](spec).

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

## Write Code

Implement your feature or bug fix.

Ruby style is enforced with [Rubocop](https://github.com/bbatsov/rubocop).
Run `bundle exec rubocop` and fix any style issues highlighted.

Make sure that `bundle exec rake` completes without errors.

## Write Documentation

Document any external behavior in the [README](README.md).

## Update Changelog

Add a line to [CHANGELOG](CHANGELOG.md) under *Next Release*.
Make it look like every other line, including your name and link to your Github account.

## Commit Changes

Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what changed and why.

```
git add ...
git commit
```

## Push

```
git push origin my-feature-branch
```

## Make a Pull Request

Go to https://github.com/contributor/canonical-emails and select your feature branch.
Click the 'Pull Request' button and fill out the form. Pull requests are usually reviewed within a few days.

## Rebase

If you've been working on a change for a while, rebase with upstream/master.

```
git fetch upstream
git rebase upstream/master
git push origin my-feature-branch -f
```

## Update CHANGELOG Again

Update the [CHANGELOG](CHANGELOG.md) with the pull request number. A typical entry looks as follows.

```
* [#123](https://github.com/dblock/canonical-emails/pull/123): Reticulated splines - [@contributor](https://github.com/contributor).
```

Amend your previous commit and force push the changes.

```
git commit --amend
git push origin my-feature-branch -f
```

## Check on Your Pull Request

Check the GitHub Actions results on your pull request and address failures.

## Be Patient

It's likely that your change will not be merged and that the nitpicky maintainers will ask you to do more, or fix seemingly benign problems. Hang on there!

## Thank You

Please do know that we really appreciate and value your time and work. We love you, really.
