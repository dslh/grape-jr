require 'action_controller'
require 'active_record'
require 'rails'
require 'grape'
require 'jsonapi-resources'

module Grape
  module JSONAPI
    Resource = ::JSONAPI::Resource
  end
end

require_relative 'jsonapi/api'
require_relative 'jsonapi/helpers'
Dir["#{File.basename __FILE__}/jsonapi/value_formatters/*.rb"].each do |lib|
  require lib
end
