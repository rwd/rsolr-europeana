# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rsolr/europeana/version'

Gem::Specification.new do |spec|
  spec.name          = "rsolr-europeana"
  spec.version       = RSolr::Europeana::VERSION
  spec.authors       = ["Richard Doe"]
  spec.email         = ["richard.doe@rwdit.net"]
  spec.description   = %q{Provides access to the Europeana REST API via an RSolr compatible interface}
  spec.summary       = %q{Access the Europeana API like a Solr server}
  spec.homepage      = ""
  spec.license       = "EUPL 1.1"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency "rsolr", "~> 1.0.6"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
