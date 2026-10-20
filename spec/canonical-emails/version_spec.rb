# frozen_string_literal: true

require 'spec_helper'
require 'bundler'
require 'open3'
require 'rbconfig'

describe CanonicalEmails do
  it 'loads the underscore entry point without Bundler preloading the version' do
    script = <<~RUBY
      require 'simplecov'
      SimpleCov.command_name 'underscore entry point'
      require 'canonical_emails'
      abort 'Missing normalization' unless CanonicalEmails.parse('A.L.E.X@gmail.com').address == 'alex@gmail.com'
      abort 'Missing extensions' unless CanonicalEmails::Extensions.respond_to?(:included)
      abort 'Missing version' unless CanonicalEmails::VERSION.match?(/\\A\\d+\\.\\d+\\.\\d+\\z/)
    RUBY
    gem_paths = (Gem.loaded_specs.values.map(&:base_dir) + Gem.path).uniq
    env = Bundler.unbundled_env.merge('GEM_PATH' => gem_paths.join(File::PATH_SEPARATOR))
    output, status = Open3.capture2e(env, RbConfig.ruby, '-Ilib', '-e', script, unsetenv_others: true)

    expect(status.success?).to be(true), output
  end

  it 'has a version' do
    expect(CanonicalEmails::VERSION).not_to be_nil
  end
end
