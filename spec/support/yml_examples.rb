def yml_examples
  caller.each do |c|
    c =~ /(.*):(\d+)/
    dir_name = File.dirname(Regexp.last_match[1])
    file_name = File.basename(Regexp.last_match[1])
    next unless file_name.end_with?('_spec.rb')
    fixture_file = "#{file_name.split('_spec').first}.yml"
    return YAML.load(File.open([dir_name, 'fixtures', fixture_file].join('/')))
  end
end
