# frozen_string_literal: true
require 'bundler/setup'
require 'simplecov'

if ENV['COVERAGE']
  SimpleCov.start do
  end
end

require 'grape/jsonapi'
require 'pry-byebug'

JSONAPI.configure do |config|
  config.json_key_format = :dasherized_key
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

Rails.env = 'test'

class TestApp < Rails::Application
  config.eager_load = false
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: 'session'
  config.secret_key_base = 'secret'
  ActiveRecord::Schema.verbose = false
end

ActiveRecord::Base.establish_connection(
  YAML.load_file(File.expand_path('../config/database.yml', __FILE__))['test']
)

TestApp.initialize!
require_relative 'fixtures/active_record'
