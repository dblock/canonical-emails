$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'canonical-emails'
require 'yaml'

%w(support shared).each do |path|
  Dir["#{File.dirname(__FILE__)}/#{path}/**/*.rb"].each do |f|
    require f
  end
end

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end
