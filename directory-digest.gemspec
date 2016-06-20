# -*- encoding: utf-8 -*-

$LOAD_PATH << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |specification|
  specification.name = 'directory-digest'
  specification.version = '1.0.2'
  specification.authors = ['Andrew Heald']
  specification.email = 'andrew@heald.uk'
  specification.homepage = 'https://github.com/sappho/gem-directory-digest'
  specification.summary = 'Creates a SHA256 digest of all of the files in a directory.'
  specification.description = 'Creates a SHA256 digest of all of the files in a directory. ' \
                              'See the project home page for more information.'
  specification.files = Dir['lib/**/*']
  specification.require_paths = %w(lib)
  specification.add_development_dependency 'rake', '~> 11.1', '>= 11.1.2'
  specification.add_development_dependency 'rubocop', '~> 0.40.0'
  specification.add_development_dependency 'rspec', '~> 3.4'
end
