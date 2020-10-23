# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'grape/jsonapi/version'

Gem::Specification.new do |spec|
  spec.name = 'grape-jsonapi'
  spec.version = Grape::JSONAPI::VERSION
  spec.authors = ['Doug Hammond']
  spec.email = ['douglas@gohiring.com']
  spec.description = 'jsonapi-resources integration for Grape'
  spec.summary = 'Provides Grape endpoints that serve resources in '\
                 'accordance with the JSON API specification.'
  spec.homepage = ''
  spec.license = 'MIT'
  spec.files = `git ls-files -z`.split("\x0")
                                .reject { |f| f.match(%r{^spec/}) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6.0'

  %w[
    bundler otr-activerecord rake rspec rubocop pry-byebug simplecov sqlite3
    rspec-rails json-schema
  ].each do |gem|
    spec.add_development_dependency gem
  end

  spec.add_runtime_dependency 'grape', '>= 1.4.0'
  spec.add_runtime_dependency 'jsonapi-resources', '~> 0.9.11'
end
