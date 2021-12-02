# frozen_string_literal: true

require_relative 'lib/michigan/version'

Gem::Specification.new do |spec|
  spec.name          = 'michigan'
  spec.version       = Michigan::VERSION
  spec.authors       = ['Brandon Vrooman']
  spec.email         = ['brandon.vrooman@gmail.com']

  spec.summary       = 'Framework for defining API client operations'
  spec.homepage      = 'https://github.com/bvrooman/michigan'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rest-client'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
end
