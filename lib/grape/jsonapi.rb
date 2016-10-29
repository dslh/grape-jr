# frozen_string_literal: true
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
require_relative 'jsonapi/value_formatters/iso_utc_timestamp_value_formatter'
require_relative 'jsonapi/value_formatters/float_value_formatter'
