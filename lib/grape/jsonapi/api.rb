# frozen_string_literal: true
require_relative 'relationships'

module Grape
  module JSONAPI
    # Uses the jsonapi-resources gem to provide a JSON-API compliant Grape::API.
    class API < ::Grape::API
      def self.inherited(subclass)
        super
        subclass.jsonapi_resource
      end

      class << self
        include Relationships

        def jsonapi_resource
          content_type :json, ::JSONAPI::MEDIA_TYPE
          default_format :json

          resource name.demodulize.underscore do
            helpers { include Helpers }

            get { process_request(:index) }
            post { process_request(:create) }

            id_route
          end
        end

        def id_route
          route_param :id do
            get { process_request(:show) }
            patch { process_request(:update) }

            add_resource_relationships(options)
          end
        end
      end
    end
  end
end
