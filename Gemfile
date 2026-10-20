# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'activesupport', ENV.fetch('ACTIVESUPPORT_VERSION', '~> 8.1.0')
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.13'
gem 'rubocop', '~> 1.92', require: false

group :development do
  gem 'danger', require: false
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
end
