# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rsolr/europeana/version'

Gem::Specification.new do |spec|
  spec.name          = 'rsolr-europeana'
  spec.version       = RSolr::Europeana::VERSION
  spec.authors       = ['Richard Doe']
  spec.email         = ['richard.doe@rwdit.net']
  spec.description   = 'Provides access to the Europeana REST API via an
                        RSolr compatible interface'
  spec.summary       = 'Access the Europeana API like a Solr server'
  spec.homepage      = 'https://github.com/rwd/rsolr-europeana'
  spec.license       = 'EUPL 1.1'

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'rsolr', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'webmock', '~> 1.20'
  spec.add_development_dependency 'simplecov'
end
