# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'simplecov'
require 'rspec'
require 'logger'
require 'active_support/core_ext/string/inflections'
require 'canonical-emails'
require 'yaml'

%w[support shared].each do |path|
  Dir["#{File.dirname(__FILE__)}/#{path}/**/*.rb"].each do |f|
    require f
  end
end

RSpec.configure(&:raise_errors_for_deprecations!)
