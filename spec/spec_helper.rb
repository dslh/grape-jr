# frozen_string_literal: true
require 'bundler/setup'
require 'simplecov'

if ENV['COVERAGE']
  SimpleCov.start do
  end
end

require 'grape/jsonapi'
require 'pry-byebug'

require 'active_record/fixtures'
require 'rspec/rails'

JSONAPI.configure do |config|
  config.json_key_format = :dasherized_key
end

require_relative 'support/jsonapi_helpers'
require_relative 'support/jsonapi_matchers'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include JsonapiHelpers
  config.use_transactional_fixtures = true
  config.fixture_path = File.expand_path('../fixtures', __FILE__)
end

Rails.env = 'test'

class TestApp < Rails::Application
  config.eager_load = false
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: 'session'
  config.secret_key_base = 'secret'
  ActiveRecord::Schema.verbose = false
end

db_configurations =
  YAML.load_file(File.expand_path('../config/database.yml', __FILE__))
ActiveRecord::Base.establish_connection db_configurations['test']
ActiveRecord::Base.configurations = db_configurations

TestApp.initialize!

require_relative 'fixtures/active_record'
require_relative 'support/formatters'
