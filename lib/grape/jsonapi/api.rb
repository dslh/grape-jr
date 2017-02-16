# frozen_string_literal: true
require_relative 'relationships'
require_relative 'error_renderer'

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

          handle_errors

          declare_base_route
        end

        def declare_base_route
          resource name.demodulize.underscore.dasherize do
            helpers { include Helpers }

            get { process_request(:index) }
            if resource_class.mutable?
              post { process_request(:create) }
            else
              post { forbidden_operation }
            end

            declare_id_route
          end
        end

        def declare_id_route
          route_param :id do
            get { process_request(:show) }
            declare_id_route_mutations

            add_resource_relationships(options)
          end
        end

        def declare_id_route_mutations
          if resource_class.mutable?
            patch { process_request(:update) }
            delete { process_request(:destroy) }
          else
            patch { forbidden_operation }
            delete { forbidden_operation }
          end
        end

        def handle_errors
          rescue_from Grape::Exceptions::Base do |error|
            ErrorRenderer.new(env).render(
              ::JSONAPI::Error.new(
                code: error.status.to_s,
                status: Rack::Utils::SYMBOL_TO_STATUS_CODE.key(error.status),
                title: error.message
              )
            )
          end
        end
      end
    end
  end
end
