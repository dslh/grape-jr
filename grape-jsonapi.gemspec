# coding: utf-8
# frozen_string_literal: true
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
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

  %w(
    bundler otr-activerecord rake rspec rubocop pry-byebug simplecov sqlite3
    rspec-rails json-schema
  ).each do |gem|
    spec.add_development_dependency gem
  end

  spec.add_runtime_dependency 'grape', '~> 1.2.0'
  spec.add_runtime_dependency 'jsonapi-resources', '~> 0.9'
end
