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
require_relative 'jsonapi/value_formatters/date_with_utc_timezone_value_formatter'
