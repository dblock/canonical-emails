$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'canonical-emails/version'

Gem::Specification.new do |s|
  s.name = 'canonical-emails'
  s.version = CanonicalEmails::VERSION
  s.authors = ['Daniel Doubrovkine']
  s.email = 'dblock@dblock.org'
  s.platform = Gem::Platform::RUBY
  s.required_rubygems_version = '>= 1.3.6'
  s.files = `git ls-files`.split("\n")
  s.require_paths = ['lib']
  s.homepage = 'http://github.com/dblock/canonical-emails'
  s.licenses = ['MIT']
  s.summary = 'Combine email validation and transformations to produce canonical email addresses.'
  s.add_dependency 'mail'
  s.add_dependency 'activesupport'
end
