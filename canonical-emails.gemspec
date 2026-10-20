# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'canonical-emails/version'

Gem::Specification.new do |s|
  s.name = 'canonical-emails'
  s.version = CanonicalEmails::VERSION
  s.authors = ['Daniel Doubrovkine']
  s.email = 'dblock@dblock.org'
  s.platform = Gem::Platform::RUBY
  s.required_rubygems_version = '>= 1.3.6'
  s.required_ruby_version = '>= 3.1'
  s.files = Dir['lib/**/*.rb', 'README.md', 'LICENSE.md', 'CHANGELOG.md', 'UPGRADING.md']
  s.require_paths = ['lib']
  s.homepage = 'https://github.com/dblock/canonical-emails'
  s.licenses = ['MIT']
  s.summary = 'Combine email validation and transformations to produce canonical email addresses.'
  s.add_dependency 'activesupport'
  s.add_dependency 'mail'
  s.metadata['rubygems_mfa_required'] = 'true'
end
